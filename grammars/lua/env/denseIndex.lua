local function denseIndex(self, key)
	local value = newproxy(true)
	getmetatable(value).__tostring = function()
		return key
	end
	self[key] = value
	return value
end

return function(settings)
	return denseIndex
end