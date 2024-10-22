local function insert(t, v)
	if t then
		t[#t + 1] = v
	end
	return v
end

local function set(t, k, v)
	if t then
		t[k] = v
	end
	return v
end

local opt_test = {}
local function isDef(v)
	return v[opt_test] ~= v
end

local Symbol = {}
function Symbol:__tostring()
	return self.token
end

local function _s(name)
	return setmetatable({
		token = name;
		usedefs = {};
	}, Symbol)
end

local TYPE = {
	BRANCH = _s 'BRANCH';
	DO = _s 'DO';
	IF = _s 'IF';
	FOR = _s 'FOR';
	FOR_GENERIC = _s 'FOR_GENERIC';
	WHILE = _s 'WHILE';
	REPEAT = _s 'REPEAT';
	ASSIGN = _s 'ASSIGN';
	FUNC = _s 'FUNC';
	DEF = _s 'DEF';
	CALL = _s 'CALL';
	RETURN = _s 'RETURN';
	BREAK = _s 'BREAK';

	BOOL = _s 'BOOL';
	FUNCTION = _s 'FUNCTION';
	TABLE = _s 'TABLE';
	STRING = _s 'STRING';
	NUMBER = _s 'NUMBER';
	REF = _s 'REF';
	NIL = _s 'NIL';
	VARARG = _s 'VARARG';
	EXP = _s 'EXP';
}

local Context = {}
function Context:__call(name)
	local sym = self.symbols[name]
	if not sym then
		sym = self.parent(name)
		if not sym then
			sym = _s(name)
			self.global.symbols[name] = sym
		end
		self.parent(name)
		self.symbols[name] = sym
		self.upvalues[name] = sym
	end
	return sym
end

function new_context(context)
	local new = setmetatable({
		parent = context;
		symbols = {};
		upvalues = {};
	}, Context)
	new.global = context and context.global or new
	return new
end

function new_scope(context)
	return insert(context.scopes, {})
end

return function(settings)
	local syntax = settings.require 'grammars/lua/ContextFreeGrammar'
	syntax:extend()

	function variable(node, context, ast)
		local token = node.token
		if context.isName then
			return insert(ast, token)
		end

		local syms = context.symbols
		local s = syms[token]
		if not s then
			s = setmetatable({
				token = token
			}, Symbol)
			syms[token] = s
		end
		return insert(ast, {
			type = TYPE.REF;
			value = s;
		})
	end

	function decimal(node, context, ast)
		return insert(ast, {
			type = TYPE.NUMBER;
			value = tonumber(node.token)
		})
	end

	function String(node, context, ast)
		return insert(ast, {
			type = TYPE.STRING;
			value = node.token;
		})
	end

	local function op(node, context, ast)
		ast.op = node[1].token
	end
	UNARY_OP = op
	BINARY_OP = op

	local function exp(node, context, ast)
		node(context, insert(ast, {}))
	end
	UNI_EXP = exp
	BIN_EXP = exp

	delimiter['...'] = function(node, context, ast)
		return insert(ast, {
			type = TYPE.VARARG;
		})
	end

	function keyword(node, context, ast)
		if node.token == 'local' then
			ast['local'] = true
		elseif node.token == 'true' then
			return insert(ast, {
				type = TYPE.BOOLEAN;
				value = true;
			})
		elseif node.token == 'false' then
			return insert(ast, {
				type = TYPE.BOOLEAN;
				value = false
			})
		elseif node.token == 'return' then
			ast.type = {RETURN}
		elseif node.token == 'break' then
			ast.type = {BREAK}
		elseif node.token == 'nil' then
			return insert(ast, {
				type = TYPE.NIL;
			})
		end
	end

	function CHUNK(node, context, ast)
		context = insert(context, new_context())
		node(context, set(ast, 'chunk', {}))
	end

	local function stmt(type)
		return function(node, context, ast)
			return node(context, insert(ast, {
				type = {type}
			}))
		end
	end
	
	BRANCH = stmt(TYPE.BRANCH)
	ASSIGN = stmt(TYPE.ASSIGN)
	CALL = stmt(TYPE.CALL)
	LAST_STATEMENT = stmt()

-- BRANCH
	function DO(node, context, ast)
		insert(ast.type, TYPE.DO)
	end

	function CONDITION(node, context, ast)
		ast.condition = node(context, {})
	end

	function WHILE(node, context, ast)
		insert(ast.type, TYPE.WHILE)
		node(context, ast)
	end

	function REPEAT(node, context, ast)
		insert(ast.type, TYPE.REPEAT)
		node(context, ast)
	end

	function IF(node, context, ast)
		insert(ast.type, TYPE.IF)
		node(context, ast)
	end

	function ELSEIF(node, context, ast)
		ast = insert(ast, {})
		node(context, ast)
	end

	function ELSE(node, context, ast)
		ast = insert(ast, {})
		node(context, ast)
	end

	function FOR(node, context, ast)
		insert(ast.type, TYPE.FOR)
		ast.variable = node.variable(context)
		node.EXP_LIST(context, ast)
		node.CHUNK(context, ast)
	end

	function VARIABLE_LIST(node, context, ast)
		ast.vars = node(context, {})
	end

	function FOR_GENERIC(node, context, ast)
		insert(ast.type, TYPE.FOR_GENERIC)
		node(context, ast)
	end

-- ASSIGN
	function FUNC(node, context, ast)
		insert(ast.type, TYPE.FUNC)
		node.FUNC_NAME(context, set(ast, 'name', {}))
		node.FUNC_BODY(context, ast)
	end

	function LOCAL_FUNC(node, context, ast)
		insert(ast.type, TYPE.FUNC)
		ast.name = node.variable(context)
		node.FUNC_BODY(context, ast)
		node['local'](context, ast)
	end

	function METHOD(node, context, ast)
		context.isName = true
		ast.method = node.variable(context)
		context.isName = false
	end

	function PARAMS(node, context, ast)
		node(context, set(ast, 'params', {}))
	end

	function ARGS(node, context, ast)
		node(context, set(ast, 'args', {}))
	end

	function ANON_FUNC(node, context, ast)
		node(context, insert(ast, {
			type = TYPE.FUNCTION;
		}))
	end

	local function def(node, context, ast)
		insert(ast.type, TYPE.DEF)
		ast.vars = node.VAR_LIST(context, {})
		node.EXP_LIST(context, ast)
		node['local'](context, ast)
	end
	DEF = def
	LOCAL_DEF = def

	function VAR(node, context, ast)
		local var = node.variable
		local v
		if isDef(var) then
			v = var(context, ast)
		elseif context.isIndex then
			v = node(context, ast)
		else
			context.isIndex = true
			v = node(context, insert(ast, {}))
			context.isIndex = nil
		end
		return v
	end

-- CALL
	function PREFIX(node, context, ast)
		for i, k in ipairs{'VAR', 'CALL', 'EXP'} do
			local v = node[k]
			if isDef(v) then
				return v(context, ast)
			end
		end
	end

	function EXP(node, context, ast)
		return node[1](context, ast)
	end

	function BRACKET_EXP(node, context, ast)
		return node.EXP(context, ast)
	end

	function DOT_INDEX(node, context, ast)
		context.isName = true
		node(context, ast)
		context.isName = false
	end

	function TABLE(node, context, ast)
		local t = {}
		insert(ast, {
			type = TYPE.TABLE;
			value = t;
		})
		node(context, t)
	end

	function NAMED_FIELD(node, context, ast)
		local val = node[3](context)
		ast[node[1](context)] = val
	end

return syntax
end