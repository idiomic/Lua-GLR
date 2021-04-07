local Assembly = {}

function Assembly.new(arg1, arg2, op)
	-- If the second argument doesn't exist,
	-- assume the first argument is optional
	op = arg2 and op or Assembly.Opt

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

	-- This allows cyclic first loops to be tracked
	value.first[value] = true

	arg1.references[value] = 'left'
	if arg2 then
		arg2.references[value] = 'right'
	end

	return value
end

function Assembly:grabFirst(index)
	for key in next, self[index].first do
		if key.isTerminal then
			self.first[key] = true
		end
	end
end

-- Extend the first into assemblies which reference
-- this one.
function Assembly:extendFirst(index)
	if self.isFirstFound then
		return
	end

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

function Assembly:combineFirsts(others)
	local start = others[self]
	for assembly, level in next, others do
		if level > start and assembly.first ~= self.first then
			-- Assembly and Production firsts always contain themselves
			-- So we can simply add all their firsts to ours
			-- References (nonterminal productions) are resolved later
			-- Additional cycles will rewrite the firsts of these references
			for first in next, assembly.first do
				self.first[first] = true
				if not first.isTerminal then
					first.first = self.first
				end
			end
			assembly.first = self.first
		end
	end
end

-- Called if cycles prevent first from being found
-- goes top down and combines cycles
function Assembly:aggregateFirst(visited, count)
	if self.isFirstFound then
		return
	elseif visited[self] then
		return self:combineFirsts(visited)
	end

	visited[self] = count
	if self.required.left then
		self.left:aggregateFirst(visited, count + 1)
		self:grabFirst 'left'
	end

	self.op.aggregateFirst(self, visited, count)

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
			compileFollow(visited, value, result)
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
	if self.right then
		self.right:compileFollow()
	end
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
		return Assembly.new(self)
	elseif op == '*' then
		if self.rep then
			return self.rep
		end
		local env = getfenv(2)
		local auto = env._NUM_AUTOS + 1
		env._NUM_AUTOS = auto
		auto = '_ASSEMBLY_REP_AUTO_' .. auto
		env[auto] = self
		env[auto] = autoSemanticAction
		self.rep = env[auto]
		env[auto].isRepeated = true
		env[auto].isOptional = true
		return self.rep
	elseif op == '+' then
		-- Totally not a violation of the rule above
		return self * self '*'
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

return function(settings)
	Assembly.Or = settings.require 'productions/Or'
	Assembly.And = settings.require 'productions/And'
	Assembly.Opt = settings.require 'productions/Opt'
	return Assembly
end