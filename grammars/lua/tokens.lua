local delimiters = require 'grammars/lua/delimiters'
local whitespace = require 'grammars/lua/whitespace'
local keywords = require 'grammars/lua/reserved'

local input = io.open('input', 'r')
io.input(input)
local source = io.read '*all'
io.close(input)
local sourceBytes = {source:byte(1, source:len())}

local states = {}
local state = 'start'
local byte = sourceBytes[1]
local nextByte = sourceBytes[2]
local add

function states.ignore()
	state = 'start'
	return false
end

function states.lineComment()
	if byte == 10 or byte == 13 then
		state = 'start'
		return
	else
		return false
	end
end

function states.multilineComment()
	if byte == 93 and nextByte == 93 then
		state = 'ignore'
	end
	return false
end

function states.comment2()
	if byte == 91 and nextByte == 91 then
		state = 'multilineComment'
	else
		state = 'lineComment'
	end
	return false
end

function states.comment()
	if nextByte == 91 then
		state = 'comment2'
	else
		state = 'lineComment'
	end
	return false
end

function states.quote()
	if nextByte == 39 then
		add 'String'
		state = 'ignore'
		return false
	elseif nextByte == 10 or nextByte == 13 then
		add 'invalid'
		state = 'start'
		return false
	else
		return true
	end
end

function states.doubleQuote()
	if nextByte == 34 then
		add 'String'
		state = 'ignore'
		return false
	elseif nextByte == 10 or nextByte == 13 then
		add 'invalid'
		state = 'start'
		return false
	else
		return true
	end
end

local bracketLevel
local curLevel
function states.bracketEnd()
	if nextByte == 61 then
		curLevel = curLevel - 1
		return true
	elseif nextByte == 93 and curLevel == 0 then
		state = 'ignore'
		return false
	else
		state = 'bracketRemember'
		add 'append'
		return false
	end
end
function states.bracketRemember()
	if nextByte == 93 then
		add 'String'
		state = 'bracketEnd'
		curLevel = bracketLevel
		return false
	else
		return true
	end
end
function states.bracketStart()
	if nextByte == 61 then
		bracketLevel = bracketLevel + 1
		return true
	elseif nextByte == 91 then
		state = 'bracketRemember'
		return false
	else
		state = 'invalid'
	end
end

function states.vararg()
	add 'delimiter'
	state = 'start'
	return false
end

function states.concat()
	if nextByte == 46 then
		state = 'vararg'
		return true
	else
		add 'delimiter'
		state = 'start'
		return false
	end
end

function states.binary()
	add 'delimiter'
	state = 'start'
	return false
end

function states.delimiter()
	if byte == 45 and nextByte == 45 then
		state = 'comment'
		return false
	elseif byte == 91 and (nextByte == 91 or nextByte == 61) then
		bracketLevel = 0
		state = 'bracketStart'
	elseif byte == 34 then
		state = 'doubleQuote'
	elseif byte == 39 then
		state = 'quote'
	elseif byte == 46 and nextByte == 46 then
		state = 'concat'
		return true
	elseif nextByte == 61 and (byte == 60 or byte == 61 or byte == 62 or byte == 126) then
		state = 'binary'
		return true
	else
		state = 'start'
		add 'delimiter'
		return false
	end
end

function states.skip()
	if whitespace[byte] then
		return false
	else
		state = 'start'
	end
end

function states.invalid()
	if delimiters[byte] then
		add 'invalid'
		state = 'start'
		return false
	else
		return true
	end
end

function states.number()
	if delimiters[nextByte] then
		add 'number'
		state = 'start'
		return false
	elseif byte >= 58 then
		state = 'invalid'
	else
		return true
	end
end

function states.variable()
	if delimiters[nextByte] then
		add 'variable'
		state = 'start'
		return false
	else
		return true
	end
end

function states.start()
	if whitespace[byte] then
		state = 'skip'
	elseif delimiters[byte] then
		state = 'delimiter'
	else
		state = byte < 58 and 'number' or 'variable'
	end
end

local literals = {}
local types = {}
local lines = {}
local ranges = {}
local curLine = 1
local tokenStart = 1
local tokenEnd = 1
local sourceLen = #sourceBytes

function add(tokenType)
	if tokenType == 'String' then
		tokenStart = tokenStart + 1
	end
	local token = source:sub(tokenStart, tokenEnd)
	if tokenType == 'append' then
		local n = #literals
		literals[n] = literals[n] .. token
		lines[n] = curLine
		ranges[n][2] = tokenEnd
		tokenStart = tokenEnd + 1
		return
	elseif tokenType == 'variable' and keywords[token] then
		tokenType = 'keyword'
	end
	local n = #literals + 1
	literals[n] = token
	types[n] = tokenType
	lines[n] = curLine
	ranges[n] = {tokenStart, tokenEnd}
	tokenStart = tokenEnd + 1
end

while tokenEnd <= sourceLen do
	if byte == 10 then
		curLine = curLine + 1
	end

	--print(state, byte, nextByte)

	local remember = states[state](byte, nextByte)
	if remember ~= nil then
		tokenEnd = tokenEnd + 1
		byte = nextByte
		nextByte = sourceBytes[tokenEnd + 1] or 0
		if remember == false then
			tokenStart = tokenEnd
		end
	end
end

if state ~= 'start' then
	add 'invalid'
else
	add 'eof'
end

--[[
for i, token in ipairs(literals) do
	print(i, token, types[i], lines[i], ranges[i][1], ranges[i][2])
end
]]

return {
	literals = literals,
	types = types,
	lines = lines,
	ranges = ranges
}