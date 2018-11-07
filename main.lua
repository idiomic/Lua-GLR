local settings = {}

function settings.require(src)
	return require(src)(settings)
end

function settings.debugPrint(...)
	return print(...)
end

function settings.read(src)
	local input = io.open('input', 'r')
	io.input(input)
	local source = io.read '*all'
	io.close(input)
	return source
end

local syntax = settings.require 'grammars/tableParser/semantics'
local tokens = settings.require 'grammars/lua/tokens'
local SLR = settings.require 'generators/SLR(1)'
local parse = settings.require 'parsers/GLR'
local deepPrint = settings.require 'util/deepPrint'

print(deepPrint(parse(SLR(syntax), syntax, tokens)))