local Collection
local tostring, dstart, dfinish, dprint

local settings

local function generate(syntax)
	local start = syntax.productions.START
	if not start then
		error('The given syntax must be augmented with nonterminal START', 2)
	end

	syntax:findFollow()

	local DFA, reductionToStates = Collection(syntax, start)

	if settings.DEBUG_SLR1_goto then
		dstart 'DFA / goto table = {'
		for i, go in next, DFA do
			dstart('(' .. tostring(i) .. ') '
				.. tostring(go) ..' = {')
			for on, to in next, go do
				dprint(tostring(on), to)
			end
			dfinish '}'
		end
		dfinish '}'
	end

	if settings.DEBUG_SLR1_reductions then
		dstart 'Reductions = {'
		for reduction, states in next, reductionToStates do
			dstart 'reduction = {'

			dprint('symbol ' .. tostring(reduction.production))

			dstart 'at = {'
			for i in next, states do
				dprint('(' .. tostring(i) .. ') ' .. tostring(DFA[i]))
			end
			dfinish '}'

			local on = {}
			for sym in next, reduction.production.follow do
				on[#on + 1] = tostring(sym)
			end
			dprint('on ' .. table.concat(on, ', '))

			dfinish '}'
		end
		dfinish '}'
	end

	for reduction, states in next, reductionToStates do
		for i in next, states do
			local state = DFA[i]
			for nextSymbol in next, reduction.production.follow do
				local trans = state[nextSymbol]
				if not trans then
					state[nextSymbol] = reduction
				elseif type(trans) == 'table' and not trans[1] then
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
	tostring = settings.require 'util/tostring'
	dprint = settings.dprint
	dstart = settings.dstart
	dfinish = settings.dfinish
	Collection = settings.require 'collections/LR(0)'
	return generate
end