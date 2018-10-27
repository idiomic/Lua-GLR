local INIT_NODES = {
	[{
		cur = 1;
		semanticRecords = {};
	}] = true;
}

local performAction
local visited
local newNodes
local terminal
local DFA

-- Set to 'function() end' to turn off debugging
local print = print

local function newNode(up, state, prev, production)
	local new = visited[state]

	if new then
		new.up[up] = true
		new.prev[prev] = true
	else
		new = {
			cur = state;
			up = {[up] = true};
			prev = {[prev] = true};
			production = production;
			semanticRecords = production.semanticAction and {};
		}
		visited[state] = new
	end

	return new
end

local l = 0
local s = '    '
local function shift(node, action)
	print(s:rep(l + 1) .. "Shift", node.cur, action)

	newNodes[newNode(node, action, node, terminal)] = true
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
			performAction(newNode(upNode, gotoState, node, reduction.production))
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
			reduce(node, altAction)
		end
	end
	print(s:rep(l) .. "End")
end

return function(parseTable, terminals)
	DFA = parseTable

	local nodes = INIT_NODES
	local rootNodes

	-- Parse tokens
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
		if not rootNodes then
			rootNodes = nodes
		end
	end

	local numSolutions = 0
	for _ in next, nodes do
		numSolutions = numSolutions + 1
	end

	-- Reverse valid stacks, stepped between shifts
	local allNodes = {} -- from top to bottom
	local fringe
	local newFringe = nodes
	while next(newFringe) do
		fringe = newFringe
		newFringe = {}
		local node = next(fringe)
		repeat
			allNodes[#allNodes + 1] = node

			if node.prev then
				for prevNode in next, node.prev do
					local addTo = node.up[prevNode] and newFringe or fringe
					addTo[prevNode] = true
				end
			end

			fringe[node] = nil
			node = next(fringe)
		until not node
	end

	-- Call semantic actions
	for i = #allNodes - 1, 1, -1 do
		local node = allNodes[i]
		if node.production.semanticAction then
			local semanticRecord, key = node.production.semanticAction(node.semanticRecords)
			print(node.cur, node.production, semanticRecord)
			local records = node.up.semanticRecords
			if records then
				records[key or #records + 1] = semanticRecord
			end
		else
			print(node.cur, node.production)
		end
	end

	return numSolutions
end