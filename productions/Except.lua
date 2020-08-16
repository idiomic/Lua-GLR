local Except = {name = '(%s ^ %s)'}

function Except:extendFirst(index)
	if self.required.right or self.required.left then
		return
	end

	for key, value in next, self.left.first do
		if key.isTerminal and not (self.right.first[key] or self.right.first[key.tokenType['']]) then
			self.first[key] = value
		end
	end

	return true
end

function Except:aggregateFirst(visited, count)
	error 'This except operation\'s first was not extended'
end

function Except:addFollow()
	self.left:addFollow(self.follow)
end

function Except:expand(expansions)
	return self.left:expand(expansions)
end

return function()
	return Except
end