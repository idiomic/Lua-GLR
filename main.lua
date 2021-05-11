-- Using a wrapper around require allows quick integration
-- into envirionments in which require works differently.
local settings = require 'settings'
local require = settings.require
local tostring = settings.tostring

-- Language CFG augmented with semantic actions to produce an AST
local syntax = require 'grammars/lua/AbstractSyntaxTree'

-- Language tokenizer
local tokenize = require 'grammars/lua/tokens'

-- Parser generator
local SLR = require 'generators/SLR(1)'

-- GLR parser to handle even ambiguous grammars
local GLR = require 'parser/GLR'

-- Intepreter of parse trees to run semantic actions
local fireActions = require 'parser/actions'

-- If input source files are not given, read './input.txt'
local sources = arg
if #sources == 0 then
	sources[1] = 'input.txt'
end

-- Read in each input
local parser = SLR(syntax)
for i, source in ipairs(sources) do
	print(source)
	-- Tokenize the source
	local tokens = tokenize(settings.read(source))

	-- Interpret the tokens
	local trees = GLR(parser, syntax, tokens)

	-- For unambiguous grammars, there will always be
	-- a single parse tree
	for tree in next, trees do
		-- These semantic actions expect an AST to output
		-- and a starting context
		local ctx, ast = {}, {}
		fireActions(tree, ctx, ast)

		-- Show the resulting AST
		print(tostring(ast))
	end
end