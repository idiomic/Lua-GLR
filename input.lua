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