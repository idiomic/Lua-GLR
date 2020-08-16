local settings = {
	DEBUG_syntax_expansions = false;
	DEBUG_syntax_terminals = false;
	DEBUG_LR0 = true;
}

function settings.require(src)
	return require(src)(settings)
end

do
	local tab = '   |'
	local n_tabs = 0
	function settings.dprint(str, ...)
		return print(tab:rep(n_tabs) .. str, ...)
	end

	function settings.dstart(str)
		settings.dprint('\n' .. str)
		n_tabs = n_tabs + 1
	end

	function settings.dfinish(str)
		n_tabs = n_tabs - 1
		settings.dprint(str .. '\n')
	end

	function settings.read(src)
		local input = io.open('input', 'r')
		io.input(input)
		local source = io.read '*all'
		io.close(input)
		return source
	end
end

-- utils
local deepPrint = settings.require 'util/deepPrint'
local deepCopy = settings.require 'util/deepCopy'
settings.deepPrint = deepPrint
settings.deepCopy = deepCopy

local syntax = settings.require 'grammars/lua/semantics'
local tokenize = settings.require 'grammars/lua/tokens'
local SLR = settings.require 'generators/SLR(1)'
local parse = settings.require 'parsers/GLR'

print(deepPrint(parse(SLR(syntax), syntax, tokenize(settings.read 'input'))))