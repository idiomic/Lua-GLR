--[[
	Syntax

	An collection of data, methods, and metamethods inserted
	into an envirionment to allow the definition of CFG
	grammers and semantic actions in a simple syntax.

	Creates productions from global variables which were
	undefined before Syntax.define() is called. Uppercase
	names result in nonterminal productions, and lowercase
	names result in terminal sets (as defined in the lexor).
	Indexing terminal sets matches the exact index key when
	the lexor associates it with the terminal set.

	The start production is defined in the generators, this
	file simply allows defining productions and operations
	on them.
]]

-- Required modules
local Assembly, Production

local Syntax = {}
local Environment = {}
Syntax.__index = Syntax

local envToSyntax = {}

local settings


-- Begins defining a new grammar
function Syntax.define()
	local env = {
		oldEnv = getfenv(2),
		_NUM_AUTOS = 0
	}
	setfenv(2, env)

	local new = setmetatable({
		terminals = {};
		productions = {};
		terminal_types = {};
	}, Syntax)
	envToSyntax[env] = new

	setmetatable(env, Environment)
	
	return new
end

-- Begins defining an existing grammar
function Syntax:extend()
	local env = {oldEnv = getfenv(2)}
	setfenv(2, env)

	-- TODO: fix _NUM_AUTOS not affecting original

	envToSyntax[env] = self

	setmetatable(env, Environment)
end

-- Finds the set of possible first terminals
-- for each non-terminal production
function Syntax:findFirst()
	-- Only needs to be called once, the results are cached.
	if self.isFirstDefined then
		return
	end
	self.isFirstDefined = true

	-- Since cycles may exist, we need to extend terminals up
	-- and check downward from the production definitions
	-- to aggregate results.

	-- For each terminal type
	for _, terminalType in next, self.terminals do
		-- For each terminal
		for _, terminal in next, terminalType do
			-- Extend up the assembly trees
			terminal:extendFirst()
		end
	end

	-- For each production
	for _, production in next, self.productions do
		production:aggregateFirst({}, 0)
	end
end

-- Finds the set of possible terminals after a non-terminal.
-- This allows us to determine the valid conditions in the
-- syntax that signify the end of a production.
function Syntax:findFollow()
	-- Only needs to be called once, the results are cached.
	if self.isFollowDefined then
		return
	end
	
	-- We need to ensure that the first sets are defined
	if not self.isFirstDefined then
		self:findFirst()
	end
	self.isFollowDefined = true

	-- First for each production, we send our firsts to
	-- the previous productions
	for _, production in next, self.productions do
		production:addFollow{}
	end

	-- Then we compile these sets into a single set of
	-- following symbols
	for _, production in next, self.productions do
		production:compileFollow{}
	end
end

-- Expands the production into all possible combinations.
-- Aggregate all expansions for the entire syntax.
function Syntax:expand()
	if self.isExpanded then
		return
	end
	self.isExpanded = true

	-- Aggregate the expansions and max length
	local expansions = {}
	local maxLen = 0

	-- For each production
	for _, production in next, self.productions do
		-- expand it
		production:expand()
		-- for each of its expansions
		for expansion in next, production.expansions do
			-- keep track of the longest
			if #expansion > maxLen then
				maxLen = #expansion
			end
			-- give it an ID and add it to the list of
			-- all expansions for the syntax
			local id = #expansions + 1
			expansion.id = id
			expansions[id] = expansion
		end
	end
	-- Cache results
	expansions.maxLen = maxLen
	self.expansions = expansions

	-- Optional debugging
	if settings.DEBUG_syntax_expansions then
		settings.dstart 'Expansions: ['
		for i, expansion in ipairs(expansions) do
			settings.dprint(tostring(i) .. ' ' .. tostring(expansion))
		end
		settings.dfinish ']'
	end
end

-- An internal function maping lexor tokens and types
-- to their matching grammer terminals / terminal sets
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

-- Gets / creates an existing / new grammar
-- production / terminal set for the name
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

-- Sets a production's definition assembly / production
-- or semantic action.
function Syntax:set(key, value)
	if type(value) == 'function' then
		local prod = self:get(key, true)
		if not prod then
			error('Attempt to add a semantic action to "'
				.. tostring(key)
				.. '" which was not defined in the syntax.', 2)
		end
		prod.semanticAction = value
		return
	end

	if key ~= key:upper() then
		error('Attempt to define a terminal symbol type "'
			.. tostring(key)
			.. '". Did you mean to define a local variable?', 2)
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