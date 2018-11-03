local Assembly = require 'productions/Assembly'
local Expansion = require 'productions/Expansion'

local Production = {}

function Production.new(tokenType, token)
	local isTerminal = tokenType and true or false

	local new = setmetatable({
		tokenType = tokenType;
		token = token;
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
		references = {};
		semanticAction = false;
	}, Production)

	if isTerminal then
		new.first = {[new] = true}
		tokenType[token] = new
	end
	return new
end

function Production:extendFirst()
	if self.isExtended then
		return
	end
	self.isExtended = true

	if not self.isTerminal then
		if self.isDefined then
			self.first = self.definition.first
			self.isFirstFound = true
		else
			error('Nonterminal ' .. tostring(self) .. ' was not defined', 2)
		end
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
		error('Nonterminal ' .. tostring(self) .. ' was not defined', 2)
	end

	self.definition:aggregateFirst(visited, count)
	self.first = self.definition.first
	self.first[self] = true
	self.isFirstFound = true
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
		local follow = {}
		self.follow = follow
		compileFollow({}, self.follow, follow)
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
	elseif not self.isExpanded then
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
		print(key, self)
		error('Attempt to index a nonterminal production', 2)
	end
end

function Production:__mul(other)
	return Assembly.new(self, other, Assembly.And)
end
function Production:__add(other)
	return Assembly.new(self, other, Assembly.Or)
end
function Production:__call(op)
	if op == '?' then
		return Assembly.new(self)
	elseif op == '*' then
		self.isOptional = true
		self.isRepeated = true
		return self
	else
		error 'Attempt to call an assembly of productions'
	end
	return self
end
function Production:__tostring() return self.token ~= '' and self.token or '[terminal type]' end
Production.class = 'Production'

return Production