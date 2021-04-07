local And = {name = '(%s and %s)'}

local DEBUG_extendFirst
local DEBUG_aggregateFirst

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
	if DEBUG_extendFirst then
		local first = {}
		for k, v in next, self.first do
			if k.isTerminal then
				first[#first + 1] = tostring(k)
			end
		end
		print('extend', self, table.concat(first, ', '))
	end

	return true
end

function And:aggregateFirst(visited, count)
	if self.required.right and self.left.isOptional then
		self.right:aggregateFirst(visited, count + 1)
		self:grabFirst 'right'
	end

	setOptional(self)
	if DEBUG_aggregateFirst then
		local first = {}
		for k, v in next, self.first do
			if k.isTerminal then
				first[#first + 1] = tostring(k)
			end
		end
		print('aggregate', self, table.concat(first, ', '))
	end
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

return function(settings)
	DEBUG_aggregateFirst = settings.DEBUG_aggregateFirst
	DEBUG_extendFirst = settings.DEBUG_extendFirst
	return And
end