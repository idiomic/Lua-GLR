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

local function insertOrCreate(t, v, ...)
	local keys = {...}
	for i = 1, #keys - 1, 1 do
		local k = keys[i]
		if not t[k] then
			t[k] = {}
		end
		t = t[k]
	end
	t[keys[#keys]] = v
end

local function create(syntax, startProd)
	syntax:expand()

	local expansionToFinish = {[0] = 0}
	local expansionToStart = {}
	local itemToSymbol = {}
	local itemToStates = {}
	local itemToExpansion = {}
	local itemToI = {}
	local stateToKernel = {}
	local stateToStates = {}

	local function kernelToString(kernel)
		local exps = {}
		for item in next, kernel do
			local exp = itemToExpansion[item]
			if not exp then
				exps[#exps + 1] = '[START | FINISH]'
			else
				local i = itemToI[item]
				local tokens = {tostring(exp.production), '{'}
				for j, prod in ipairs(exp) do
					if j == i then
						tokens[#tokens + 1] = '.'
					end
					tokens[#tokens + 1] = tostring(prod)
				end
				if i > #exp then
					tokens[#tokens + 1] = '.'
				end
				tokens[#tokens + 1] = '}'
				exps[#exps + 1] = table.concat(tokens, ' ') 
			end
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

		for i, symbol in ipairs(expansion) do
			itemToSymbol[itemID] = symbol
			itemToStates[itemID] = {}
			itemToI[itemID] = i
			itemToExpansion[itemID] = expansion
			itemID = itemID + 1
		end

		-- The final item of an expansion doesn't contain a symbol
		itemToSymbol[itemID] = false
		itemToStates[itemID] = {}
		itemToI[itemID] = #expansion + 1
		itemToExpansion[itemID] = expansion

		expansionToFinish[expansionID] = itemID
	end

	local isRepeated = {}
	itemToStates[isRepeated] = {}
	local isOptional = {}
	itemToStates[isOptional] = {}

	-- Create the start state
	local startItem = expansionToStart[next(startProd.expansions).id]
	stateToKernel[1] = {[startItem] = true}
	stateToStates[1] = {}
	itemToStates[startItem][1] = 1

	-- Process all kernels by:
	--   finding required productions to produce kernel items
	--   creating sets of items transitioning on symbols
	--   from those sets, finding or creating the kernel of new states
	local state = 1
	repeat
		local states = stateToStates[state]

		-- Collect all items transitioning on the same symbol
		local closed = {}
		local fringe = {}

		-- Start exploring our kernel items
		local n = 0
		for item in next, stateToKernel[state] do
			n = n + 1
			fringe[n] = item
			closed[item] = true
		end

		while n > 0 do
			local item = fringe[n]
			fringe[n] = nil
			n = n - 1

			-- Find which symbol is next for this item
			local symbol = itemToSymbol[item]

			-- Final items have no symbol, no additional productions to add
			if symbol then
				local nextID = item + 1

				-- We need to encode information in the states, refs are not
				-- actual symbols output by the tokenizer and thus cannot
				-- be used in transitions. In addition, it would cause different
				-- refs to lead to different states.
				if symbol.isRef then
					local prod = symbol.production

					-- Transition to the next item in the expansion on that symbol
					-- If not already done by another kernel item, perform a set of
					-- all states transitioning on this symbol.
					insertOrCreate(states, true, prod, nextID)

					-- If the symbol of this kernel item is optional, then the next
					-- symbol also belongs in the kernel.
					if symbol.isOptional then
						states[prod][isOptional] = true
						if not closed[nextID] then
							closed[nextID] = true
							n = n + 1
							fringe[n] = nextID
						end
					end

					if symbol.isRepeated then
						insertOrCreate(states, true, prod, item)
						states[prod][isRepeated] = true
					end
				else
					-- Transition to the next item in the expansion on that symbol
					-- If not already done by another kernel item, perform a set of
					-- all states transitioning on this symbol.
					insertOrCreate(states, true, symbol, nextID)
				end

				-- In order for the symbol to be produced, we need to include its
				-- expansions. These will reduce the symbol back to this state,
				-- and this state will have the above shift.
				for expansion in next, symbol.expansions do
					local expID = expansionToStart[expansion.id]
					if not closed[expID] then
						closed[expID] = true
						n = n + 1
						fringe[n] = expID
					end
				end
			end
		end

		-- Get or create the state these items go to
		for prod, items in next, states do
			-- Detect identical kernels
			local toState = getKernel(items)

			-- If there is no identical kernel, create one
			-- This new kernel will be processed as well.
			if not toState then
				toState = #stateToStates + 1
				stateToKernel[toState] = items
				stateToStates[toState] = {}
				for kernelItem in next, items do
					itemToStates[kernelItem][toState] = true
				end
			end

			states[prod] = toState
		end

		state = state + 1
	until state > #stateToStates

	local reductionToStates = {}
	for exp, start in next, expansionToStart do
		local states = {}
		for item = expansionToFinish[exp], start, -1 do
			for state in next, itemToStates[item] do
				states[state] = true
			end
			local s = itemToSymbol[item]
			if s and not s.isOptional then
				break
			end
		end
		reductionToStates[syntax.expansions[exp]] = states
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