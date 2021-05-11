local performAction
local newNodes
local terminal
local DFA
local token
local cache

local dprint
local dstart
local dfinish

local DEBUG
local DEBUG_goto

local function printStack(node)
	local stack = {}
	while node do
		stack[#stack + 1] = tostring(node.production)
		node = node.prev
	end
	for i = 1, math.floor(#stack / 2) do
		local j = #stack - i + 1
		stack[i], stack[j] = stack[j], stack[i]
	end
	dprint('node stack = {', table.concat(stack, ' '), '}')
end

local function shift(node, action)
	if DEBUG then
		dprint('shift', action, tostring(DFA[action]))
	end

	local new = {
		cur = action;
		prev = node;
		token = token;
		production = terminal;
	}
	newNodes[new] = true
end

local function reduce(prev, reduction)
	local popedNodes = {}
	for i = #reduction, 1, -1 do
		local handled = false
		if reduction[i].isRef then
			if reduction[i].production == prev.production then
				popedNodes[#popedNodes + 1] = prev
				prev = prev.prev
				handled = true
			end

			if reduction[i].isRepeated then
				while reduction[i].production == prev.production do
					popedNodes[#popedNodes + 1] = prev
					prev = prev.prev
				end
			end
		elseif reduction[i] == prev.production then
			popedNodes[#popedNodes + 1] = prev
			prev = prev.prev
			handled = true
		end
		if not handled and not reduction[i].isOptional then
			if DEBUG then
				dprint('missing non-optional productions for ' .. tostring(reduction))
				dprint('next production: ' .. tostring(reduction[i]))
				printStack(prev)
			end
			return
		end
	end

	local prod = reduction.production
	local to = DFA[prev.cur][prod]
	local new_node = {
		cur = DFA[prev.cur][prod];
		prev = prev;
		production = prod;
		popedNodes = popedNodes;
	}

	if DEBUG then
		local names = {}
		for i = #popedNodes, 1, -1 do
			names[i] = tostring(popedNodes[#popedNodes - i + 1].production)
		end
		dstart 'reduce = {'
		dprint('reduction', tostring(reduction))
		dprint('popped', table.concat(names, ' '))
		if DEBUG_goto then
			dstart('goto table of ' .. tostring(prev.cur) .. ' ' .. tostring(DFA[prev.cur]) .. ' = {')
			for prod, state in next, DFA[prev.cur] do
				dprint(prod, ' = ', state)
			end
			dfinish '} (popped)'
		else
			dprint('goto table of ' .. tostring(prev.cur) .. ' ' .. tostring(DFA[prev.cur]))
		end
		dprint('goto ', tostring(to), tostring(DFA[to]))
		printStack(new_node)
		dfinish '} (reduce)'
	end

	return performAction(new_node)
end

-- GLR parsers must merge when ambiguity gets resolved
local function isCached(leafNode)
	for otherNode in next, cache do
		local node = leafNode
		local isMatch = true
		while isMatch and node and otherNode do
			isMatch = node.cur == otherNode.cur
				and node.production == node.production
			node = node.prev
			otherNode = otherNode.prev
		end
		if isMatch then
			return true
		end
	end

	cache[leafNode] = true
	return false
end

local function _performAction(node, _action)
	if not _action then
		if DEBUG then
			printStack(node)
			dprint('No action')
		end
		return
	end

	if type(_action) == 'number' then
		return shift(node, _action)
	elseif _action[1] then
		return reduce(node, _action)
	end

	if DEBUG then
		dstart 'split = {'
		for altAction in next, _action do
			dstart 'thread = {'
			if type(altAction) == 'number' then
				shift(node, altAction)
			else
				reduce(node, altAction)
			end
			dfinish '} (thread)'
		end
		dfinish '} (split)'
	else
		for altAction in next, _action do
			if type(altAction) == 'number' then
				shift(node, altAction)
			else
				reduce(node, altAction)
			end
		end
	end
end

function performAction(node)
	if isCached(node) then
		if DEBUG then
			printStack(node)
			dprint 'Cached'
		end
		return
	end

	if not node.cur then
		if DEBUG then
			printStack(node)
			dprint("Reached an invalid parsing state")
		end
		return
	end

	-- Check the more general path for this token as well
	-- e.g. "delimiter[';']" also triggers actions for "delimiter"
	if terminal.token ~= '' then
		local action = DFA[node.cur][terminal.tokenType['']]
		if action then
			if DEBUG then
				dstart 'Token Class = {'
				_performAction(node, action)
				dfinish '} (token class)'
			else
				_performAction(node, action)
			end
		end
	end

	return _performAction(node, DFA[node.cur][terminal])
end

local function parse(parseTable, syntax, tokens)
	DFA = parseTable

	local nodes = {[{
		cur = 1,
		production = syntax.productions.START,
		popedNodes = {}
	}] = true}

	-- Parse tokens
	local terminals = syntax:getTerminals(tokens)
	for i = 1, #terminals do
		terminal = terminals[i]
		token = tokens.literals[i]

		if DEBUG then
			print('\n')
			print(tostring(terminal))
		end
		cache = {}
		newNodes = {}
		for node in next, nodes do
			if DEBUG then
				dstart 'Parse Tree Leaf = {'
				for key, value in next, node do
					dprint(key, value)
				end
				dprint('')
			end
			performAction(node)
			if DEBUG then
				dfinish '} (parse tree leaf)'
			end
		end
		nodes = newNodes
	end

	return nodes
end

return function(settings)
	dprint = settings.dprint
	dstart = settings.dstart
	dfinish = settings.dfinish
	DEBUG = settings.DEBUG_GLR
	DEBUG_goto = settings.DEBUG_GLR_goto
	return parse
end