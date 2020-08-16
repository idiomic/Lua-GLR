local Conjugate = {name = '(%s ^ %s)'}

local function grabHalfConjFirst(self, a, b)
	for key, value in next, a do
		if key.isTerminal and (b[key] or b[key.tokenType['']]) then
			self.first[key] = value
		end
	end
end

function Conjugate:extendFirst(index)
	if self.required.right or self.required.left then
		return
	end
	
	-- Required to loop through both lists since one first list may
	-- contain a general type and the other has instances of it
	grabHalfConjFirst(self, self.left.first, self.right.first)
	grabHalfConjFirst(self, self.right.first, self.left.first)

	return true
end

function Conjugate:aggregateFirst(visited, count)
	error 'This conjugate operation\'s first was not extended'
end

function Conjugate:addFollow()
	-- This is only possible because we are guarenteed to be working on
	-- an assembly of or directly on terminals, no productions involved
	for key, value in next, self.first do
		key:addFollow(self.follow)
	end
end

function Conjugate:expand(expansions)
	local newExpansions = {}
	for token in next, self.first do
		if token.isTerminal then
			for expansion in next, expansions do
				newExpansions[{
					value = token;
					next = expansion;
				}] = true
			end
		end
	end
	return newExpansions
end

return function()
	return Conjugate
end