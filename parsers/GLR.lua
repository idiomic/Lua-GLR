local INIT_NODE = {
	[{cur = 1}] = true;
}

local performAction
local visited
local newNodes
local terminal
local DFA

-- Set to 'function() end' to turn off debugging
local print = print

local function newNode(up, state)
	local new = visited[state]

	if new then
		new.up[up] = true
	else
		new = {
			cur = state;
			up = {[up] = true};
		}
		visited[state] = new
	end

	return new
end

local l = 0
local s = '    '
local function shift(node, action)
	print(s:rep(l + 1) .. "Shift", node.cur, action)

	newNodes[newNode(node, action)] = true
end

local getAncesters
function getAncesters(node, i, result)
	if i > 1 then
		i = i - 1
		for upNode in next, node.up do
			getAncesters(upNode, i, result)
		end
	else
		for upNode in next, node.up do
			result[upNode] = true
		end
	end
end

local function reduce(node, reduction)
	l = l + 1
	local upNodes = {}
	getAncesters(node, #reduction, upNodes)

	for upNode in next, upNodes do
		local gotoState = DFA[upNode.cur][reduction.production]
		print(s:rep(l) .. "Reduce", node.cur, reduction, upNode.cur, gotoState)
		if visited[gotoState] and visited[gotoState].up[upNode] then
			print(s:rep(l) .. "Already Evaluated")
		else
			performAction(newNode(upNode, gotoState))
		end
	end
	l = l - 1
end

function performAction(node)
	local action = DFA[node.cur][terminal]
	if not action then
		print(s:rep(l) .. "No Action", node.cur, terminal)
		return
	end

	if type(action) == 'number' then
		return shift(node, action)
	end

	print(s:rep(l) .. "Begin")
	for altAction in next, action do
		if type(altAction) == 'number' then
			shift(node, altAction)
		else
			reduce(node, altAction, action)
		end
	end
	print(s:rep(l) .. "End")
end

return function(parseTable, terminals)
	DFA = parseTable

	local nodes = INIT_NODE
	for _, t in ipairs(terminals) do
		newNodes = {}
		visited = {}
		terminal = t

		print()
		print('------------------------------', terminal)
		print()

		for node in next, nodes do
			local success, msg = pcall(performAction, node)
			if not success then
				print("Begin Error Stack:")
				while node.up do
					print(node.cur)
					node = next(node.up)
				end
				print(1)
				error(msg)
			end
			print()
		end

		nodes = newNodes
	end

	print("Finished with:")
	for node in next, nodes do
		print(node.cur)
	end

	return nodes
end