local Expansion = {}
Expansion.__index = Expansion

function Expansion.new(tokenArray, production)
	tokenArray.production = production -- Will I pay for this ugly hack? We'll see.
	return setmetatable(tokenArray, Expansion)
end

function Expansion:__tostring()
	local tokenStrings = {}
	for i, token in ipairs(self) do
		tokenStrings[i] = tostring(token)
	end
	return ('%s{%s}'):format(tostring(self.production), table.concat(tokenStrings, ' '))
end

return function()
	return Expansion
end