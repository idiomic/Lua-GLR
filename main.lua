local syntax = require 'grammars/lua/syntax'
local tokens = require 'grammars/lua/tokens'
local createDFA = require 'generators/SLR(1)'
local parse = require 'parsers/GLR'

local DFA = createDFA(syntax)
print(parse(DFA, syntax:getTerminals(tokens)))