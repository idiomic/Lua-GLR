local smt = setmetatable
local gmt = getmetatable
local next = next
local type = type

local cache
local function deepCopy(src)
	if cache[src] then
		return cache[src]
	end

	local dst = {}
	cache[src] = dst

	for k, v in next, src do
		if type(k) == 'table' then
			k = deepCopy(k)
		end
		if type(v) == 'table' then
			v = deepCopy(v)
		end
		dst[k] = v
	end

	return smt(dst, gmt(src))
end

local function firstCall(src)
	cache = {}
	local copy = deepCopy(src)
	cache = nil
	return copy
end

return function()
	return firstCall
end