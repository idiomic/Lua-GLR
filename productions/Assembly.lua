local Assembly = {
	Or = require 'productions/Or';
	And = require 'productions/And';
}

function Assembly.new(arg1, arg2, op)
	local value = setmetatable({
		op = op;
		isOptional = false;
		isFirstFound = false;
		first = {};
		-- Storing references for assemblies allows some pretty
		-- cool things, like using variables when defining a syntax
		references = {};
		required = {
			left = true;
			right = arg2 and true or nil; -- must be nil if missing
		};
		left = arg1;
		right = arg2;
	}, Assembly)

	value.first[value] = true

	arg1.references[value] = 'left'
	if arg2 then
		arg2.references[value] = 'right'
	end

	return value
end

function Assembly:grabFirst(index)
	if self[index].isTerminal then
		self.first[self[index]] = true
	else
		for key, value in next, self[index].first do
			-- don't grab connection data.
			-- bad stuff ensues. Trust me.
			if key.isTerminal then
				self.first[key] = value
			end
		end
	end
end

function Assembly:extendFirst(index)
	self.required[index] = false

	if self.op and not self.op.extendFirst(self, index) then
		return
	end

	self.isFirstFound = true

	for assembly, toIndex in next, self.references do
		if assembly ~= self then
			assembly:extendFirst(toIndex)
		end
	end
end

-- used when cyclic dependencies are found
-- makes changing one affect the other
function Assembly:combineFirsts(others, index)
	for assembly, level in next, others do
		if level >= index and assembly.first ~= self.first then
			for key, value in next, assembly.first do
				self.first[key] = value
				if not key.isTerminal then
					key.first = self.first
				end
			end
		end
	end
end

-- Called if cycles prevent first from being found
-- goes top down and combines cycles
function Assembly:aggregateFirst(visited, count)
	if self.isFirstFound then
		return
	elseif visited[self] then
		return self:combineFirsts(visited, visited[self])
	end

	visited[self] = count
	if self.required.left then
		self.left:aggregateFirst(visited, count + 1)
		self:grabFirst 'left'
	end

	if self.op then
		self.op.aggregateFirst(self, visited, count)
	end
	visited[self] = nil

	self.isFirstFound = true
end

function Assembly:addFollow(follow, isRepeated)
	if self.follow then
		self.follow[follow] = true
	else
		self.follow = {[follow] = true}
	end

	if isRepeated or self.isRepeated then
		for key, value in next, self.first do
			if key.isTerminal then
				self.follow[key] = value
			end
		end
	end

	if not self.addedFollow then
		self.addedFollow = true
		self.op.addFollow(self)
	end
end

local compileFollow
function compileFollow(visited, follow, result)
	for value, key in next, follow do
		if value == 'FINISH' or value.isTerminal then
			result[value] = true
		elseif not visited[value] then
			visited[value] = true
			if type(value) == 'table' then
				compileFollow(visited, value, result)
			else
				error(value, key)
			end
		end
	end
end

function Assembly:compileFollow()
	if self.isFollowCompiled then
		return
	end
	self.isFollowCompiled = true

	local follow = {}
	compileFollow({}, self.follow, follow)
	self.follow = follow

	self.left:compileFollow()
	self.right:compileFollow()
end

function Assembly:expand(expansions)
	local new = self.op.expand(self, expansions)
	if self.isOptional then
		for expansion in next, expansions do
			new[expansion] = true
		end
	end
	return new
end

function Assembly:__mul(other) return self:new(other, Assembly.And) end
function Assembly:__add(other) return self:new(other, Assembly.Or) end

local function autoSemanticAction(f, o)
	return f(o)
end

function Assembly:__call(op)
	if op == '?' then
		self.isOptional = true
	elseif op == '*' then
		-- We should be throwing an error here telling the user that this
		-- operation can only be performed on a nonterminal, but since
		-- usability and approachability is a higher priority right now,
		-- this functionallity has been hacked in. Once a syntax for syntax
		-- definition has been created along with a transpiler to Lua, this
		-- ugly hack will become obsolete.
		if self.rep then
			return self.rep
		end
		local env = getfenv(2)
		local auto = env._NUM_AUTOS + 1
		env._NUM_AUTOS = auto
		auto = '_AUTO_' .. auto
		env[auto] = self
		env[auto] = autoSemanticAction
		self.rep = env[auto]
		return self.rep '*'
	else
		error 'Attempt to call an assembly of productions'
	end
	return self
end

function Assembly:__tostring()
	if self.op then
		return self.op.name:format(tostring(self.left), tostring(self.right))
	else
		return tostring(self.left)
	end
end
Assembly.class = 'Assembly'
Assembly.__index = Assembly

return Assembly