local keywords
local byte, nextByte
local add, skip

local b = string.byte

local settings

local function isWhitespace(c)
	-- Space or Tab
	return c == b' ' or c == b'\t'
end

local function isDelimiter(c)
	return not (
		b'0' <= c and c <= b'9' or
		b'A' <= c and c <= b'Z' or
		b'a' <= c and c <= b'z' or
		c == 95
	)
end

local function isDecimal(c)
	return b'0' <= c and c <= b'9'
end

local function isHex(c)
	return b'0' <= c and c <= b'9'
		or b'A' <= c and c <= b'F'
		or b'a' <= c and c <= b'f'
end

local function delimiter()
	if byte == b'[' or byte == b']' then
		local i = 1
		while peek(i) == b'=' do
			i = i + 1
		end
		if peek(i) == byte then
			for j = 1, i do
				skip()
			end
		end
	elseif byte == b'.' and nextByte == b'.' then
		-- .. and ...
		skip()
		if nextByte == b'.' then
			skip()
		end
	elseif byte == b'-' and nextByte == b'-'
		or nextByte == b'=' and (byte == b'<' or byte == b'=' or byte == b'>' or byte == b'~') then
		-- operations with two symbols e.g. '<='
		-- and comments like this
		skip()
	end
	add 'delimiter'
end

local function decimal()
	local hasPoint = false
	local hasPower = false
	while true do
		if nextByte == b'.' and not (hasPoint or hasPower) then
			hasPoint = true
		elseif (nextByte == b'E' or nextByte == b'e') and not hasPower then
			hasPower = true
		elseif not isDecimal(nextByte) then
			return add 'decimal'
		end
		skip()
	end
end

local function hexadecimal()
	while isHex(nextByte) do
		skip()
	end
	add 'hexadecimal'
end

local function variable()
	while not (isWhitespace(nextByte) or isDelimiter(nextByte)) do
		skip()
	end
	add 'variable'
end

local function whitespace()
	while isWhitespace(nextByte) do
		skip()
	end
	add 'whitespace'
end

local function parseToken()
	if isWhitespace(byte) then
		return whitespace()
	elseif isDelimiter(byte) then
		return delimiter()
	elseif isDecimal(byte) then
		if byte == b'0' and nextByte == b'x' then
			skip()
			return hexadecimal()
		else
			return decimal()
		end
	else
		return variable()
	end
end

local s = "'%s', '%s', '%s'"
local function tokenize(source)
	local sourceBytes = {source:byte(1, source:len())}

	byte = sourceBytes[1]
	nextByte = sourceBytes[2]

	local literals = {}
	local types = {}
	local lines = {}
	local ranges = {}

	local curLine = 1
	local tokenStart = 1
	local tokenEnd = 1
	local sourceLen = #sourceBytes

	function peek(i)
		return sourceBytes[tokenEnd + i]
	end

	function skip(forget)
		tokenEnd = tokenEnd + 1
		byte = nextByte
		nextByte = peek(1) or 0
		if forget then
			tokenStart = tokenEnd
		end
	end

	function add(tokenType)
		local token = source:sub(tokenStart, tokenEnd)
		if tokenType == 'variable' and keywords[token] then
			tokenType = 'keyword'
		elseif tokenType == 'whitespace' or tokenType == 'delimiter' and token == '\n' then
			return
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
		parseToken()
		skip(true)
	end

	add 'eof'

	if settings.DEBUG_tokenizer then
		settings.dstart 'Tokens: ['
		local fmt = '%s\t(%s)\t%d:%d-%d'
		for i in ipairs(literals) do
			settings.dprint(fmt:format(literal, types[i], lines[i], ranges[i][1], ranges[i][2]))
		end
		settings.dfinish ']'
	end

	return {
		literals = literals,
		types = types,
		lines = lines,
		ranges = ranges
	}
end

return function(cur_settings)
	settings = cur_settings
	keywords = settings.require 'grammars/lua/reserved'
	return tokenize
end