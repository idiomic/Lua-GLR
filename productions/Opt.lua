local Or = {name = '(%s or %s)'}

local function setOptional(self)
	self.isOptional = true
end

function Or:extendFirst(index)
	self:grabFirst(index)
	setOptional(self)
	return true
end

function Or:aggregateFirst(visited, count)
	setOptional(self)
end

function Or:addFollow()
	self.left:addFollow(self.follow)
end

function Or:expand(expansions)
	local leftExpansions = self.left:expand(expansions)

	for key, value in next, expansions do
		leftExpansions[key] = value
	end

	return leftExpansions
end

return Or