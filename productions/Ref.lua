local Ref = {}
local methods = {}

local Assembly

function methods:expand(expansions)
	local new = {}
	for expansion in next, expansions do
		new[{
			value = self;
			next = expansion;
		}] = true
	end
	return new
end

function Ref:__index(key)
	return self.production[key]
end

function Ref:__call(op)
	return self.production(op)
end

function Ref:__mul(other)
	return Assembly.new(self, other, Assembly.And)
end

function Ref:__add(other)
	return Assembly.new(self, other, Assembly.Or)
end

function Ref:__tostring()
	local mod = ''
	if self.isOptional then
		if self.isRepeated then
			mod = '*'
		else
			mod = '?'
		end
	elseif self.isRepeated then
		mod = '+'
	end
	return tostring(self.production) .. mod
end

local function new(production, isOptional, isRepeated)
	return setmetatable({
		production = production;
		isOptional = isOptional;
		isRepeated = isRepeated;
		isRef = true;
	}, Ref)
end

return function(settings)
	Assembly = settings.require 'productions/Assembly'
	return new
end