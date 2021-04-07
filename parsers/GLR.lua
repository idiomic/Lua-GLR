local performAction
local newNodes
local terminal
local DFA
local token
local cache

local dprint
local dstart
local dfinish

local function shift(node, action)
	dprint('shift', action)
	local new = {
		cur = action;
		prev = node;
		token = token;
		production = terminal;
	}
	newNodes[new] = true
end

local function reduce(prev, reduction)
	if #reduction == 0 and prev.production == reduction.production then
		return
	end

	local names = {}
	local popedNodes = {}
	for i = 1, #reduction do
		popedNodes[i] = prev
		names[#reduction - i + 1] = tostring(prev.production)
		prev = prev.prev
	end

	local prod = reduction.production
	dstart 'reduce = {'
	dprint('expansion', tostring(reduction))
	dprint('popped', table.concat(names, ' '))
	dfinish '}'
	return performAction {
		cur = DFA[prev.cur][prod];
		prev = prev;
		production = prod;
		popedNodes = popedNodes;
	}
end

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
		return
	end

	if type(_action) == 'number' then
		return shift(node, _action)
	end

	dstart 'split = {'
	for altAction in next, _action do
		if type(altAction) == 'number' then
			shift(node, altAction)
		else
			reduce(node, altAction)
		end
	end
	dfinish '}'
end

function performAction(node)
	if isCached(node) then
		return
	end

	-- Check the more general path for this token as well
	-- e.g. "delimiter[';']" also triggers actions for "delimiter"
	if terminal.token ~= '' then
		_performAction(node, DFA[node.cur][terminal.tokenType['']])
	end

	return _performAction(node, DFA[node.cur][terminal])
end

local function fireActions(node, ...)
	local prod = node.production
	local action = prod.semanticAction
	if not action and prod.isTerminal then
		prod = prod.tokenType['']
		action = prod.semanticAction
	end

	if action then
		local i = node.token
		if not i then
			i = function(...)
				for j = #node.popedNodes, 1, -1 do
					fireActions(node.popedNodes[j], ...)
				end
				return ...
			end
		end

		action(i, ...)
	elseif not node.token then
		for j = #node.popedNodes, 1, -1 do
			fireActions(node.popedNodes[j], ...)
		end
	end
end

local function parse(parseTable, syntax, tokens)
	DFA = parseTable

	local nodes = {[{cur = 1}] = true}

	-- Parse tokens
	local terminals = syntax:getTerminals(tokens)
	for i = 1, #terminals do
		terminal = terminals[i]
		token = tokens.literals[i]

		print('\n')
		print(tostring(terminal))
		cache = {}
		newNodes = {}
		for node in next, nodes do
			dstart 'CurNode = {'
			for key, value in next, node do
				dprint(key, value)
			end
			dfinish '}'
			performAction(node)
		end
		nodes = newNodes
	end

	local results = {}
	for node in next, nodes do
		fireActions(node.prev, results)
	end
	return results
end

return function(settings)
	dprint = settings.dprint
	dstart = settings.dstart
	dfinish = settings.dfinish
	return parse
end