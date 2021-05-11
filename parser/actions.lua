local ActionTree = {}

local OPT
OPT = setmetatable({}, {
	__call = function() end,
	__index = function() return OPT end,
})

local ElementsAreOpt = {
	__index = function()
		return OPT
	end
}

function ActionTree.new(node, parent)
	local prod = node.production
	local action = prod.semanticAction
	local byOrder = {}
	local byName = {}

	if prod.isTerminal then
		if not action then
			prod = prod.tokenType['']
			action = prod.semanticAction
		end
	else
		local mult = node.production.multiplicity
		local nodes = node.popedNodes
		for i = #nodes, 1, -1 do
			child = ActionTree.new(nodes[i])
			byOrder[#byOrder + 1] = child
			local name = tostring(child.production)
			if byName[name] then
				byName[name][#byName[name] + 1] = child
			elseif mult[child.production] then
				byName[name] = {child}
			else
				byName[name] = child
			end
		end
	end

	return setmetatable({
		parent = parent;
		expanded = false;
		action = action;
		running = false;
		childrenByOrder = byOrder;
		childrenByName = setmetatable(byName, ElementsAreOpt);
		token = node.token;
		production = node.production;
	}, ActionTree)
end

function ActionTree:__index(key)
	if type(key) == 'number' then
		return self.childrenByOrder[key]
	elseif type(key) == 'string' then
		return self.childrenByName[key]
	end
end

function ActionTree:__call(context, ...)
	if self.running or not self.action then
		for i, child in ipairs(self.childrenByOrder) do
			child(context, ...)
		end
	elseif self.action then
		self.running = true
		local ret_values = {self.action(self, context, ...)}
		self.running = false
		if #ret_values > 0 then
			return unpack(ret_values), ...
		end
	end
	return ...
end

function ActionTree:__tostring()
	return tostring(self.production)
end

local function fireActions(node, ...)
	return ActionTree.new(node.prev)(...)
end

return function(settings)
	return fireActions
end