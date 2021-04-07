local Or = {name = '(%s or %s)'}

local DEBUG_extendFirst
local DEBUG_aggregateFirst

local function setOptional(self)
	self.isOptional = self.isOptional or self.left.isOptional or self.right.isOptional
end

function Or:extendFirst(index)
	self:grabFirst(index)

	if self.required.left or self.required.right then
		return
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

function Or:aggregateFirst(visited, count)
	if self.required.right then
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

function Or:addFollow()
	self.right:addFollow(self.follow)
	self.left:addFollow(self.follow)
end

function Or:expand(expansions)
	local leftExpansions = self.left:expand(expansions)
	local rightExpansions = self.right:expand(expansions)

	for key, value in next, rightExpansions do
		leftExpansions[key] = value
	end

	return leftExpansions
end

return function(settings)
	DEBUG_aggregateFirst = settings.DEBUG_aggregateFirst
	DEBUG_extendFirst = settings.DEBUG_extendFirst
	return Or
end