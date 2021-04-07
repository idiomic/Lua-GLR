local Collection
local deepPrint

local settings

local function generate(syntax)
	local start = syntax.productions.START
	if not start then
		error('The given syntax must be augmented with nonterminal START', 2)
	end

	syntax:findFollow()

	print("Found follow")

	local DFA, reductionToStates = Collection(syntax, start)

	if settings.DEBUG_SLR1_goto then
		settings.dstart 'DFA / goto table = {'
		for i, go in next, DFA do
			settings.dstart('(' .. tostring(i) .. ') '
				.. tostring(go) ..' = {')
			for on, to in next, go do
				settings.dprint(tostring(on), to)
			end
			settings.dfinish '}'
		end
		settings.dfinish '}'
	end

	if settings.DEBUG_SLR1_reductions then
		settings.dstart 'Reductions = {'
		for reduction, states in next, reductionToStates do
			settings.dstart 'reduction = {'

			settings.dprint('symbol ' .. tostring(reduction.production))

			settings.dstart 'at = {'
			for i in next, states do
				settings.dprint(tostring(DFA[i]))
			end
			settings.dfinish '}'

			local on = {}
			for sym in next, reduction.production.follow do
				on[#on + 1] = tostring(sym)
			end
			settings.dprint('on ' .. table.concat(on, ', '))

			settings.dfinish '}'
		end
		settings.dfinish '}'
	end

	for reduction, states in next, reductionToStates do
		for i in next, states do
			local state = DFA[i]
			for nextSymbol in next, reduction.production.follow do
				local trans = state[nextSymbol]
				if not trans then
					state[nextSymbol] = {[reduction] = true}
				elseif type(trans) == 'table' then
					trans[reduction] = true
				else
					state[nextSymbol] = {
						[reduction] = true;
						[state[nextSymbol]] = true;
					}
				end
			end
		end
	end

	return DFA
end

return function(_settings)
	settings = _settings
	deepPrint = settings.require 'util/deepPrint'
	Collection = settings.require 'collections/LR(0)'
	return generate
end