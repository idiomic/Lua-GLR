local syntax = require 'grammars/lua/semantics'
local tokens = require 'grammars/lua/tokens'
local SLR = require 'generators/SLR(1)'
local parse = require 'parsers/GLR'

local results = parse(SLR(syntax), syntax, tokens)
print(results)