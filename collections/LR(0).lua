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

	local expansionToItem = {[0] = 0}
	local itemToSymbol = {}
	local itemToStates = {}
	local itemToExpansion = {}
	local stateToKernel = {}
	local stateToStates = {}

	-- Create all the items
	for expansionID, expansion in ipairs(syntax.expansions) do
		for _, symbol in ipairs(expansion) do
			local itemID = #itemToStates + 1
			itemToSymbol[itemID] = symbol
			itemToStates[itemID] = {}
			itemToExpansion[itemID] = expansion
		end

		-- The final item of an expansion doesn't contain a symbol
		local itemID = #itemToStates + 1
		itemToStates[itemID] = {}
		itemToExpansion[itemID] = expansion
		expansionToItem[expansionID] = itemID
	end

	-- Create the start state
	local startItem = expansionToItem[next(startProd.expansions).id - 1] + 1
	stateToKernel[1] = {[startItem] = true}
	stateToStates[1] = {}
	itemToStates[startItem][1] = 1

	local state = 1
	repeat
		local states = stateToStates[state]

		-- Collect all items transitioning on the same symbol
		local explored = {}
		local fringe = {}

		for item in next, stateToKernel[state] do
			fringe[item] = true
		end

		local item = next(fringe)
		repeat
			fringe[item] = nil
			explored[item] = true

			local symbol = itemToSymbol[item]
			if symbol then
				if states[symbol] then
					states[symbol][item + 1] = true
				else
					states[symbol] = {[item + 1] = true}
				end

				for expansion in next, symbol.expansions do
					local nextID = expansionToItem[expansion.id - 1] + 1
					if not explored[nextID] then
						fringe[nextID] = true
					end
				end
			end

			item = next(fringe)
		until not item

		-- Get or create the state these items go to
		for symbol, items in next, states do
			local toState

			if symbol.isRepeated then
				for expansion in next, symbol.expansions do
					items[expansionToItem[expansion.id - 1] + 1] = true
				end
			end

			for otherState in next, itemToStates[next(items)] do
				if shallowEqual(items, stateToKernel[otherState]) then
					toState = otherState
					break
				end
			end

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
	for i = 1, #expansionToItem do
		local item = expansionToItem[i]
		local reduction = itemToExpansion[item]
		reductionToStates[reduction] = itemToStates[item]
	end

	-- Return the transitions
	return stateToStates, reductionToStates
end

return function(cur_settings)
	settings = cur_settings
	return create
end