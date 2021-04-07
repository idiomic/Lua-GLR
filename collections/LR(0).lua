local settings

local function shallowEqual(t1, t2)
	for key, value in next, t1 do
		if t2[key] ~= value then
			return false
		end
	end

	for key, value in next, t2 do
		if t1[key] ~= value then
			return false
		end
	end

	return true
end

local function create(syntax, startProd)
	syntax:expand()

	local expansionToFinish = {[0] = 0}
	local expansionToStart = {}
	local itemToSymbol = {}
	local itemToStates = {}
	local itemToExpansion = {}
	local stateToKernel = {}
	local stateToStates = {}

	local function kernelToString(kernel)
		local exps = {}
		for item in next, kernel do
			exps[#exps + 1] = tostring(itemToExpansion[item])
		end
		return table.concat(exps, ' | ')
	end

	local function getKernel(items)
		local matching = {}
		for state in next, itemToStates[next(items)] do
			matching[state] = true
		end

		for item in next, items do
			local states = itemToStates[item]
			for state in next, matching do
				if not states[state] then
					matching[state] = nil
				end
			end
			if not next(matching) then
				return
			end
		end

		return next(matching)
	end

	-- Create all the items
	for expansionID, expansion in ipairs(syntax.expansions) do
		local itemID = #itemToStates + 1
		expansionToStart[expansionID] = itemID

		for _, symbol in ipairs(expansion) do
			itemToSymbol[itemID] = symbol
			itemToStates[itemID] = {}
			itemToExpansion[itemID] = expansion
			itemID = itemID + 1
		end

		-- The final item of an expansion doesn't contain a symbol
		itemToSymbol[itemID] = false
		itemToStates[itemID] = {}
		itemToExpansion[itemID] = expansion

		expansionToFinish[expansionID] = itemID
	end

	-- Create the start state
	local startItem = expansionToStart[next(startProd.expansions).id]
	stateToKernel[1] = {[startItem] = true}
	stateToStates[1] = {}
	itemToStates[startItem][1] = 1

	local state = 1
	repeat
		local states = stateToStates[state]

		-- Collect all items transitioning on the same symbol
		local closed = {}
		local fringe = {}

		-- Start exploring our kernel items
		for item in next, stateToKernel[state] do
			fringe[#fringe + 1] = item
			closed[item] = true
		end

		while #fringe > 0 do
			local item = fringe[#fringe]
			fringe[#fringe] = nil

			-- Find which symbol is next for this item
			local symbol = itemToSymbol[item]

			-- Final items have no symbol
			if symbol then
				-- Transition to the next item in the expansion on that symbol
				if states[symbol] then
					states[symbol][item + 1] = true
				else
					states[symbol] = {[item + 1] = true}
				end

				-- We must now include expansions to reduce that symbol
				for expansion in next, symbol.expansions do
					local nextID = expansionToStart[expansion.id]
					if not closed[nextID] then
						closed[nextID] = true
						fringe[#fringe + 1] = nextID
					end
				end
			end
		end

		-- Get or create the state these items go to
		for symbol, items in next, states do
			if symbol.isRepeated then
				for expansion in next, symbol.expansions do
					items[expansionToFinish[expansion.id - 1] + 1] = true
				end
			end

			local toState = getKernel(items)

			if not toState then
				toState = #stateToStates + 1
				stateToKernel[toState] = items
				stateToStates[toState] = {}
				for kernelItem in next, items do
					itemToStates[kernelItem][toState] = true
				end
			end

			states[symbol] = toState
		end

		state = state + 1
	until state > #stateToStates

	local reductionToStates = {}
	for i = 1, #expansionToFinish do
		local item = expansionToFinish[i]
		local reduction = itemToExpansion[item]
		reductionToStates[reduction] = itemToStates[item]
	end

	for i, states in next, stateToStates do
		setmetatable(states, {
			__tostring = function(self)
				return kernelToString(stateToKernel[i])
			end
		})
	end

	-- Return the transitions
	return stateToStates, reductionToStates
end

return function(cur_settings)
	settings = cur_settings
	return create
end