local Assembly, Expansion

local Production = {}

local settings

function Production.new(tokenType, token, typename)
	local isTerminal = tokenType and true or false

	local new = setmetatable({
		tokenType = tokenType;
		token = token;
		typename = typename;
		isProduction = true;
		isRef = false;
		isDefined = false;
		isExtended = false;
		isExpanded = false;
		isOptional = false;
		isTerminal = isTerminal;
		isFirstFound = isTerminal;
		addedFollow = false;
		expansions = {};
		multiplicity = {};
		follow = {};
		first = nil;
		references = {};
		refs = {};
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

function Production:initAddFollow()
	if self.refs.rep or self.refs.opt_rep then
		local follow = {}
		for first in next, self.first do
			if first.isTerminal then
				follow[first] = true
			end
		end
		if settings.DEBUG_rep_follow then
			settings.dstart(tostring(self) .. ' rep follow = {')
			for k, v in next, follow do
				settings.dprint(tostring(k))
			end
			settings.dfinish '}'
		end
		self:addFollow(follow)
	else
		self:addFollow{}
	end
end

function Production:addFollow(follow)
	if self.isTerminal then
		self.follow[follow] = true
	else
		self.definition:addFollow(follow)
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

function Production:dprintExps(exps)
	settings.dstart('Expanding ' .. tostring(self) .. ' = {')
	settings.dstart 'Got = {'
	for expansion in next, exps do
		local c = {}
		local cur = expansion
		while cur do
			c[#c + 1] = tostring(cur.value)
			cur = cur.next
		end
		settings.dprint(table.concat(c, ' '))
	end
	settings.dfinish '}'
	settings.dprint('Adding ' .. tostring(self))
	settings.dfinish '}'
end

function Production:expand(expansions)
	if expansions then
		if settings.DEBUG_expansions then
			self:dprintExps(expansions)
		end

		local newExpansions = {}
		for expansion in next, expansions do
			newExpansions[{
				value = self;
				next = expansion;
			}] = true
		end
		return newExpansions
	elseif self.isExpanded then
		return
	end
	self.isExpanded = true
	
	local start = {}
	expansions = {[start] = true}
	expansions = self.definition:expand(expansions)

	if settings.DEBUG_expansions then
		self:dprintExps(expansions)
	end

	local compiledExpansions = self.expansions
	for expansion in next, expansions do
		if expansion ~= start then
			local compiled = {}
			while expansion do
				compiled[#compiled + 1] = expansion.value
				expansion = expansion.next
			end
			compiled = Expansion.new(compiled, self)
			compiledExpansions[compiled] = true
		end
	end

	for expansion in next, self.expansions do
		local once = {}
		local mult = {}
		for i, sym in next, expansion do
			if sym.isRef and sym.isRepeated then
				mult[sym.production] = true
			else
				if sym.isRef then
					sym = sym.production
				end
				if not mult[sym] then
					if once[sym] then
						mult[sym] = true
					else
						once[sym] = true
					end
				end
			end
		end
		for sym in next, mult do
			self.multiplicity[sym] = true
		end
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

function Production:__call(op)
	local refs = self.refs
	if op == '+' then
		if not refs.rep then
			refs.rep = Ref(self, false, true)
		end
		return refs.rep
	elseif op == '*' then
		if not refs.opt_rep then
			refs.opt_rep = Ref(self, true, true)
		end
		return refs.opt_rep
	elseif op == '?' then
		if not refs.opt then
			refs.opt = Ref(self, true, false)
		end
		return refs.opt
	else
		error 'Attempt to call a production without ?, *, or +'
	end
	return self
end

function Production:__tostring()
	if self.token == '' then
		return self.typename
	elseif self.isTerminal then
		return self.token
	else
		return self.token
	end
end
Production.class = 'Production'

return function(_settings)
	Assembly = _settings.require 'productions/Assembly'
	Expansion = _settings.require 'productions/Expansion'
	Ref = _settings.require 'productions/Ref'
	settings = _settings
	return Production
end
