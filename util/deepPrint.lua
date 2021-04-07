local l = '   |'

local lines, cache, count
local function deepPrint(data, prefix)
	if cache[data] then
		lines[#lines + 1] = prefix .. '[' .. cache[data] .. ']'
		return
	end

	count = count + 1
	local name = 'table_' .. count
	cache[data] = name

	for key, value in next, data do
		local valuet = type(value)
		local keyt = type(key)
		if keyt == 'table' then
			lines[#lines + 1] = prefix .. '[{'
			deepPrint(key, prefix .. l)
			if valuet == 'table' then
				lines[#lines + 1] = prefix .. '}] = {'
				deepPrint(value, prefix .. l)
				lines[#lines + 1] = prefix .. '};'
			end
		elseif valuet == 'table' then
			lines[#lines + 1] = prefix .. tostring(key) .. ' = {'
			deepPrint(value, prefix .. l)
			lines[#lines + 1] = prefix .. '};'
		elseif type(value) == 'string' then
			lines[#lines + 1] = prefix .. tostring(key) .. ' = "' .. tostring(value) .. '";'
		else
			lines[#lines + 1] = prefix .. tostring(key) .. ' = ' .. tostring(value) .. ';'
		end
	end
end

local function firstCall(data)
	lines, cache, count = {}, {}, 0
	deepPrint(data, '')
	local str = table.concat(lines, '\n')
	lines, cache, count = nil, nil, nil
	return str
end

return function()
	return firstCall
end