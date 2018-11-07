local performAction
local newNodes
local terminal
local DFA
local token
local cache

local function shift(node, action)
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

	local popedNodes = {}
	for i = 1, #reduction do
		popedNodes[i] = prev
		prev = prev.prev
	end

	local prod = reduction.production
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

function performAction(node)
	if isCached(node) then
		return
	end

	local action = DFA[node.cur][terminal]
	if not action then
		return
	end

	if type(action) == 'number' then
		return shift(node, action)
	end

	for altAction in next, action do
		if type(altAction) == 'number' then
			shift(node, altAction)
		else
			reduce(node, altAction)
		end
	end
end

local function fireActions(node, ...)
	local prod = node.production
	local action = prod.semanticAction
	if not action then
		if prod.isTerminal then
			prod = prod.tokenType['']
			action = prod.semanticAction
			if not action then
				return
			end
		else
			return
		end
	end

	local i = node.token
	if not i then
		i = function(...)
			for j = #node.popedNodes, 1, -1 do
				local subNode = node.popedNodes[j]
				fireActions(subNode, ...)
			end
			return ...
		end
	end

	action(i, ...)
end

local function parse(parseTable, syntax, tokens)
	DFA = parseTable

	local nodes = {[{cur = 1}] = true}

	-- Parse tokens
	local terminals = syntax:getTerminals(tokens)
	for i = 1, #terminals do
		terminal = terminals[i]
		token = tokens.literals[i]

		cache = {}
		newNodes = {}
		for node in next, nodes do
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

return function()
	return parse
end