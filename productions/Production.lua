local Assembly, Expansion

local Production = {}

function Production.new(tokenType, token, typename)
	local isTerminal = tokenType and true or false

	local new = setmetatable({
		tokenType = tokenType;
		token = token;
		typename = typename;
		isDefined = false;
		isExtended = false;
		isExpanded = false;
		isOptional = false;
		isRepeated = false;
		isTerminal = isTerminal;
		isFirstFound = isTerminal;
		addedFollow = false;
		expansions = {};
		follow = {};
		first = nil;
		references = {};
		rep = false;
		definition = false;
		semanticAction = false;
	}, Production)

	if isTerminal then
		new.first = {[new] = true}
		tokenType[token] = new
	end
	return new
end

-- Extends this production's first to all the
-- assemblies which reference it.
function Production:extendFirst()
	if self.isExtended then
		return
	end
	self.isExtended = true

	-- Note: terminals had first defined
	-- as themselves in the constructor
	if not self.isTerminal then
		-- Nonterminals can only reach this point if their defining
		-- assembly has already computed its first set and is now
		-- calling the non-terminals it defines.
		self.first = self.definition.first
		self.isFirstFound = true
	end

	for assembly, index in next, self.references do
		assembly:extendFirst(index)
	end
end

function Production:aggregateFirst(visited, count)
	if self.isFirstFound then
		return
	end

	if not self.isDefined then
		error('Nonterminal ' .. tostring(self) .. ' was not defined', 1)
	end

	-- Note: with cyclic loops, first may be combined.
	self.definition:aggregateFirst(visited, count)
	self.first = self.definition.first
	self.first[self] = true
	self.isFirstFound = self.definition.first
	if not self.isFirstFound then
		error("First could not be compiled due to loops, additional structures are needed.")
	end
end

function Production:addFollow(follow)
	if self.isTerminal then
		self.follow[follow] = true
	else
		self.definition:addFollow(follow, self.isRepeated)
	end
end

local compileFollow
function compileFollow(visited, follow, result)
	for value in next, follow do
		if value.isTerminal then
			result[value] = true
		elseif not visited[value] then
			visited[value] = true
			compileFollow(visited, value, result)
		end
	end
end

function Production:compileFollow()
	if self.isTerminal then
		local result = {}
		compileFollow({}, self.follow, result)
		self.follow = result
	else
		self.definition:compileFollow()
		self.follow = self.definition.follow
	end
end

function Production:expand(expansions)
	if expansions then
		local newExpansions = {}
		for expansion in next, expansions do
			newExpansions[{
				value = self;
				next = expansion;
			}] = true
		end
		if self.isOptional then
			for expansion in next, expansions do
				newExpansions[expansion] = true
			end
		end
		return newExpansions
	elseif self.isExpanded then
		return
	end
	self.isExpanded = true
	
	expansions = {[{}] = true}
	expansions = self.definition:expand(expansions)
	local exps
	if self.isRepeated then
		exps = {}
		for expansion in next, expansions do
			exps[expansion] = true
			exps[{
				value = self;
				next = expansion;
			}] = true
		end
	else
		exps = expansions
	end
	local compiledExpansions = self.expansions
	for expansion in next, exps do
		local compiled = {}
		while expansion do
			compiled[#compiled + 1] = expansion.value
			expansion = expansion.next
		end
		compiled = Expansion.new(compiled, self)
		compiledExpansions[compiled] = true
	end
end

function Production:__index(key)
	if Production[key] then
		return Production[key]
	elseif self.isTerminal then
		if not self.tokenType[key] then
			Production.new(self.tokenType, key)
		end
		return self.tokenType[key]
	else
		error('Attempt to index a nonterminal production '
			.. tostring(self) .. ' with "' .. key .. '"', 2)
	end
end

function Production:__mul(other)
	return Assembly.new(self, other, Assembly.And)
end
function Production:__add(other)
	return Assembly.new(self, other, Assembly.Or)
end

local function autoSemanticAction(f, o)
	return f(o)
end
function Production:__call(op)
	if op == '?' then
		return Assembly.new(self)
	elseif op == '*' then
		local rep = self.rep or self.definition and self.definition.rep
		if rep then
			return rep
		end
		local env = getfenv(2)
		local auto = '_OPT_REP_' .. tostring(self)
		env[auto] = self
		env[auto] = autoSemanticAction
		local new = env[auto]
		self.rep = new
		new.isRepeated = true
		new.isOptional = true
		return self.rep
	elseif op == '+' then
		return self * self '*'
	else
		error 'Attempt to call an assembly of productions'
	end
	return self
end

function Production:__tostring()
	if self.token == '' then
		return self.typename
	elseif self.isTerminal then
		return "'" .. self.token .. "'"
	else
		return self.token
	end
end
Production.class = 'Production'

return function(settings)
	Assembly = settings.require 'productions/Assembly'
	Expansion = settings.require 'productions/Expansion'
	return Production
end
