local performAction
local visited
local newNodes
local terminal
local DFA
local token

local function shift(node, action)
	if not visited[action] then
		local new = {
			cur = action;
			prev = node;
			token = token;
			production = terminal;
		}
		visited[action] = new
		newNodes[new] = true
	end
end

local function reduce(node, reduction)
	local prev = node
	local popedNodes = {}
	for i = 1, #reduction do
		popedNodes[i] = prev
		prev = prev.prev
	end

	local prod = reduction.production
	local gotoState = DFA[prev.cur][prod]
	performAction {
		cur = gotoState;
		prev = prev;
		production = prod;
		popedNodes = popedNodes;
	}
end

function performAction(node)
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

local function fireActions(node, output)
	local action = node.production.semanticAction
	if not action then
		return
	end

	if node.token then
		action(node.token, output)
	else
		local records = {}
		for i = #node.popedNodes, 1, -1 do
			local subNode = node.popedNodes[i]
			fireActions(subNode, records)
		end
		action(records, output)
	end
end

return function(parseTable, syntax, tokens)
	DFA = parseTable

	local nodes = {[{cur = 1}] = true}
	local rootNodes

	-- Parse tokens
	for i, t in ipairs(syntax:getTerminals(tokens)) do
		newNodes = {}
		visited = {}
		terminal = t
		token = tokens.literals[i]

		for node in next, nodes do
			performAction(node)
		end

		nodes = newNodes
		if not rootNodes then
			rootNodes = nodes
		end
	end

	local results = {}
	for node in next, nodes do
		fireActions(node.prev, results)
	end

	return results
end