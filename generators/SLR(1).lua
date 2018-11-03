local Collection = require 'collections/LR(0)'

return function (syntax)
	local start = syntax.productions.START
	if not start then
		error('The given syntax must be augmented with nonterminal START', 2)
	end

	syntax:findFollow()

	for key, value in next, syntax.productions.CHUNK.follow do
		print(key, value)
	end

	local DFA, reductionToStates = Collection(syntax, start)

--[[ DEBUG START
	local from = {}
	for state = 1, #DFA do
		from[state] = {}
	end
	for state, toStates in ipairs(DFA) do
		for symbol, action in next, toStates do
			from[action][state] = symbol
		end
	end
-- DEBUG END ]]

	for reduction, states in next, reductionToStates do
		for state in next, states do
			for nextSymbol in next, reduction.production.follow do
				local transitionType = type(DFA[state][nextSymbol])
				if transitionType == 'table' then
					DFA[state][nextSymbol][reduction] = true
				elseif transitionType == 'nil' then
					DFA[state][nextSymbol] = {
						[reduction] = true
					}
				else
					DFA[state][nextSymbol] = {
						[reduction] = true;
						[DFA[state][nextSymbol]] = true;
					}
				end
			end
		end
	end

--[[ DEBUG START
	-- Detailed DFA (now NFA with conflicts) printer
	for state, toStates in ipairs(DFA) do
		print()
		print(state)
		print 'From:'
		for fromState, symbol in next, from[state] do
			print(fromState, 'on', symbol)
		end
		print 'To:'
		for symbol, action in next, toStates do
			if type(action) == 'table' then
				for i in next, action do
					print(i, 'on', symbol)
				end
			else
				print(action, 'on', symbol)
			end
		end
	end
-- DEBUG END ]]

	return DFA
end