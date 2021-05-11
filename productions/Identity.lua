local Identity = {name = '%s'}

local DEBUG_extendFirst
local DEBUG_aggregateFirst

local function setOptional(self)
	self.isOptional = self.isOptional or self.left.isOptional
end

function Identity:extendFirst(index)
	self:grabFirst(index)

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

function Identity:aggregateFirst(visited, count)
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

function Identity:addFollow()
	self.left:addFollow(self.follow)
end

function Identity:expand(expansions)
	return self.left:expand(expansions)
end

return function(settings)
	DEBUG_aggregateFirst = settings.DEBUG_aggregateFirst
	DEBUG_extendFirst = settings.DEBUG_extendFirst
	return Identity
end