local Assembly = require 'productions/Assembly'
local Production = require 'productions/Production'

local Syntax = {}
local Environment = {}
Syntax.__index = Syntax

local envToSyntax = {}

function Syntax.define()
	local env = getfenv(2)

	local new = setmetatable({
		terminals = {};
		productions = {};
	}, Syntax)
	envToSyntax[env] = new

	env._SYNTAX = new
	env._NUM_AUTOS = 0

	setmetatable(env, Environment)
	return new
end

function Syntax:findFirst()
	if self.isFirstDefined then
		return
	end
	self.isFirstDefined = true

	for _, terminalType in next, self.terminals do
		for _, terminal in next, terminalType do
			terminal:extendFirst()
		end
	end

	for _, production in next, self.productions do
		production:aggregateFirst({}, 0)
	end
end

function Syntax:findFollow()
	if self.isFollowDefined then
		return
	elseif not self.isFirstDefined then
		self:findFirst()
	end
	self.isFollowDefined = true

	for _, production in next, self.productions do
		production:addFollow{}
	end

	for _, production in next, self.productions do
		production:compileFollow{}
	end
end

function Syntax:expand()
	if self.isExpanded then
		return
	end
	self.isExpanded = true

	local expansions = {}
	local maxLen = 0
	for _, production in next, self.productions do
		production:expand()
		for expansion in next, production.expansions do
			if #expansion > maxLen then
				maxLen = #expansion
			end
			local id = #expansions + 1
			expansion.id = id
			expansions[id] = expansion
		end
	end
	expansions.maxLen = maxLen
	self.expansions = expansions
end

function Syntax:getTerminals(tokens)
	local terminals = {}
	local literals = tokens.literals
	local types = tokens.types
	for i, literal in ipairs(literals) do
		local general = self.terminals[types[i]]
		if not general then
			error('Token type ' .. types[i] .. ' does not exist in this syntax.', 2)
		end
		if general[literal] then
			terminals[i] = general[literal]
		else
			terminals[i] = general['']
		end
	end
	return terminals
end

function Syntax:get(key)
	if key == key:upper() then
		local storage = self.productions
		if not storage[key] then
			storage[key] = Production.new(false, key)
				or Production.new(key, '')
		end
		return storage[key]
	else
		local storage = self.terminals
		if not storage[key] then
			storage[key] = {}
			return Production.new(storage[key], '')
		end
		return storage[key]['']
	end
end

function Syntax:set(key, value)
	if key ~= key:upper() then
		error('Attempt to define a terminal symbol', 2)
	end

	local nonterminal = self:get(key)
	if value.class == 'Production' then
		value = Assembly.new(value, value, Assembly.Or)
	end

	if nonterminal.isDefined then
		value = nonterminal.definition + value
	end

	value.references[nonterminal] = true
	nonterminal.definition = value
	nonterminal.isDefined = true
end

function Environment:__index(key)
	return envToSyntax[self]:get(key)
end

function Environment:__newindex(key, value)
	envToSyntax[self]:set(key, value)
end

return Syntax