local settings = {
	DEBUG_tokenizer = false;
	DEBUG_extendFirst = false;
	DEBUG_aggregateFirst = false;
	DEBUG_rep_follow = false;
	DEBUG_follow = false;
	DEBUG_syntax_expansions = false;
	DEBUG_expansions = false;
	DEBUG_syntax_terminals = false;
	DEBUG_SLR1_goto = false;
	DEBUG_SLR1_reductions = false;
	DEBUG_GLR = false;
	DEBUG_GLR_goto = false;
}

function settings.require(src)
	return require(src)(settings)
end

local tab = ' |'
local n_tabs = 0
function settings.dprint(str, ...)
	if type(str) ~= 'string' then
		str = tostring(str)
	end
	return print(tab:rep(n_tabs) .. str, ...)
end

function settings.dstart(str, ...)
	settings.dprint(str, ...)
	n_tabs = n_tabs + 1
end

function settings.dfinish(str, ...)
	n_tabs = n_tabs - 1
	settings.dprint(str, ...)
end

function settings.read(src)
	local input = io.open(src, 'r')
	io.input(input)
	local source = io.read '*all'
	io.close(input)
	return source
end

settings.tostring = settings.require 'util/tostring'
settings.copy = settings.require 'util/copy'

return settings