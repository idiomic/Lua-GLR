local l = '   |'

local lines, cache, count, line
local function push(str)
	line = line .. str
end
local function flush(prefix)
	if line ~= '' then
		lines[#lines + 1] = prefix .. line
		line = ''
	end
end
local function pushLn(prefix, str)
	push(str)
	flush(prefix)
end

local deepPrint
local function pushVal(value, prefix)
	local name = tostring(value)
	if type(value) == 'table' then
		local mt = getmetatable(value)
		if not mt or not mt.__tostring or type(name) ~= 'string' then
			if not next(value) then
				return push '{}'
			end
			pushLn(prefix, '{')
			deepPrint(value, prefix .. l)
			flush(prefix)
			return push '}'
		end
	end

	return push(name)
end

function deepPrint(data, prefix)
	if cache[data] then
		lines[#lines + 1] = prefix .. '[' .. cache[data] .. ']'
		return
	end

	count = count + 1
	local name = 'table_' .. count
	cache[data] = name

	for key, value in next, data do
		if not (type(key) == 'number' and key >= 1 and key <= #data and key % 1 == 0) then
			pushVal(key, prefix)
			push ' = '
			pushVal(value, prefix)
			pushLn(prefix, ';')
		end
	end

	if #data > 0 then
		for i, value in ipairs(data) do
			push('[' .. tostring(i) .. '] = ')
			pushVal(value, prefix)
			pushLn(prefix, ';')
		end
	end
end

local function firstCall(data)
	lines, cache, count, line = {}, {}, 0, ''
	pushVal(data, '')
	flush ''
	local str = table.concat(lines, '\n')
	lines, cache, count = nil, nil, nil
	return str
end

return function()
	return firstCall
end