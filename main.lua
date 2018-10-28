local syntax = require 'grammars/example/semantics'
local tokenize = require 'grammars/example/tokenize'
local createDFA = require 'generators/SLR(1)'
local parse = require 'parsers/GLR'

local DFA = createDFA(syntax)
local tokens = tokenize 'select 1 thru 5 and 15 at 100'
local results = parse(DFA, syntax, tokens)

local at = results.at
for index in next, results.values do
	print(index, at)
end