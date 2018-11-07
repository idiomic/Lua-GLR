local And = {name = '(%s and %s)'}

local function setOptional(self)
	self.isOptional = self.isOptional or self.left.isOptional and self.right.isOptional
end

function And:extendFirst(index)
	if index == 'left' then
		self:grabFirst 'left'
		if self.left.isOptional and self.required.right then
			return
		end
	elseif self.required.left then
		return
	end

	if self.left.isOptional then
		self:grabFirst 'right'
	end

	setOptional(self)

	return true
end

function And:aggregateFirst(visited, count)
	if self.left.isOptional then
		self.right:aggregateFirst(visited, count + 1)
		self:grabFirst 'right'
	end

	setOptional(self)
end

function And:addFollow()
	self.right:addFollow(self.follow)
	if self.right.isOptional then
		self.left:addFollow(self.follow)
	end

	local follow = {}
	for key, value in next, self.right.first do
		if key.isTerminal then
			follow[key] = value
		end
	end
	self.left:addFollow(follow)
end

function And:expand(expansions)
	expansions = self.right:expand(expansions)
	return self.left:expand(expansions)
end

return function()
	return And
end