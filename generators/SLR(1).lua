local Collection = require 'collections/LR(0)'

return function (syntax)
	local start = syntax.productions.START
	if not start then
		error('The given syntax must be augmented with nonterminal START', 2)
	end

	syntax:findFollow()

	local DFA, reductionToStates = Collection(syntax, start)

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

	return DFA
end