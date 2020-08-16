local Assembly, Production

local Syntax = {}
local Environment = {}
Syntax.__index = Syntax

local envToSyntax = {}

local settings

function Syntax.define()
	local env = {oldEnv = getfenv(2)}
	setfenv(2, env)

	local new = setmetatable({
		terminals = {};
		productions = {};
		terminal_types = {};
	}, Syntax)
	envToSyntax[env] = new

	env._SYNTAX = new
	env._NUM_AUTOS = 0

	setmetatable(env, Environment)
	
	return new
end

function Syntax:extend()
	local env = {oldEnv = getfenv(2)}
	setfenv(2, env)

	envToSyntax[env] = self

	env._SYNTAX = self
	env._NUM_AUTOS = 0

	setmetatable(env, Environment)
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
	end
	
	if not self.isFirstDefined then
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

	if settings.DEBUG_syntax_expansions then
		settings.dstart 'Expansions: ['
		for i, expansion in ipairs(expansions) do
			settings.dprint(tostring(i) .. ' ' .. tostring(expansion))
		end
		settings.dfinish ']'
	end
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
	if settings.DEBUG_syntax_terminals then
		settings.dstart 'Terminals: ['
		local token_fmt = '%d %s'
		local literal_fmt = '%d %s "%s"'
		for i, terminal in next, terminals do
			if terminal.token == '' then
				settings.dprint(literal_fmt:format(i, terminal, literals[i]))
			else
				settings.dprint(token_fmt:format(i, terminal))
			end
		end
		settings.dfinish ']'
	end

	return terminals
end

function Syntax:get(key, no_create)
	if key == key:upper() then
		local storage = self.productions
		if not storage[key] then
			if no_create then
				return
			end
			storage[key] = Production.new(false, key)
				or Production.new(key, '')
		end
		return storage[key]
	else
		local storage = self.terminals
		if not storage[key] then
			if no_create then
				return
			end
			storage[key] = {}
			return Production.new(storage[key], '', key)
		end
		return storage[key]['']
	end
end

function Syntax:set(key, value)
	if type(value) == 'function' then
		local prod = self:get(key, true)
		if not prod then
			error('Attempt to add a semantic action to "' .. tostring(key) .. '" which was not defined in the syntax.', 2)
		end
		prod.semanticAction = value
		return
	end

	if key ~= key:upper() then
		error('Attempt to define a terminal symbol ' .. tostring(key), 2)
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
	return self.oldEnv[key] or envToSyntax[self]:get(key)
end

function Environment:__newindex(key, value)
	envToSyntax[self]:set(key, value)
end

return function(cur_settings)
	settings = cur_settings

	Assembly = settings.require 'productions/Assembly'
	Production = settings.require 'productions/Production'
	return Syntax
end