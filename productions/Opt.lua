local Opt = {name = '%s?'}

local function setOptional(self)
	self.isOptional = true
end

function Opt:extendFirst(index)
	self:grabFirst(index)
	setOptional(self)
	return true
end

function Opt:aggregateFirst(visited, count)
	setOptional(self)
end

function Opt:addFollow()
	self.left:addFollow(self.follow)
end

function Opt:expand(expansions)
	local leftExpansions = self.left:expand(expansions)

	for key, value in next, expansions do
		leftExpansions[key] = value
	end

	return leftExpansions
end

return function()
	return Opt
end