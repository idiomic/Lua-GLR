local syntax = require 'grammars/luafide/semantics'
local tokens = require 'grammars/lua/tokens'
local SLR = require 'generators/SLR(1)'
local parse = require 'parsers/GLR'

local l = '   |'
local function tablePrint(data, cache, prefix)
	if cache[data] then
		return print(prefix .. '[' .. cache[data] .. ']')
	end

	cache.count = cache.count + 1
	local name = 'table_' .. cache.count
	cache[data] = name

	for key, value in next, data do
		local valuet = type(value)
		local keyt = type(key)
		if keyt == 'table' then
			print(prefix .. '[{')
			tablePrint(key, cache, prefix .. l)
			if valuet == 'table' then
				print(prefix .. '}] = {')
				tablePrint(value, cache, prefix .. l)
				print(prefix .. '};')
			end
		elseif valuet == 'table' then
			print(prefix .. tostring(key) .. ' = {')
			tablePrint(value, cache, prefix .. l)
			print(prefix .. '};')
		else
			print(prefix .. tostring(key) .. ' = ' .. tostring(value) .. ';')
		end
	end
end
local function print(data)
	return tablePrint(data, {count = 0}, '')
end

print(parse(SLR(syntax), syntax, tokens))