local VAL_TYPE = {}
local NODE_TYPE = {}
local STMT_TYPE = {}
local NIL = {}

return function(settings)
	
local denseMT = {
	__index = settings.require 'grammars/lua/env/denseIndex';
}
setmetatable(VAL_TYPE, denseMT)
setmetatable(NODE_TYPE, denseMT)
setmetatable(STMT_TYPE, denseMT)

local syntax = settings.require 'grammars/lua/syntax'
syntax:extend()

local function rename(rep, src)
	for to, from in next, rep do
		if src[from] then
			src[to] = src[from]
			src[from] = nil
		end
	end

	return src
end

function variable(t, o)
	o[#o + 1] = {
		nodeType = NODE_TYPE.REF;
		token = t;
	}
end

function decimal(t, o)
	o[#o + 1] = tonumber(t)
end

function String(t, o)
	o[#o + 1] = t
end

local isOp = {
	['-'] = true;
	['*'] = true;
	['/'] = true;
	['^'] = true;
	['%'] = true;
	['..'] = true;
	['<'] = true;
	['<='] = true;
	['>'] = true;
	['>='] = true;
	['=='] = true;
	['~='] = true;
}

local function op(t, o)
	o.op = t
end
UNARY_OP = op
BINARY_OP = op

function delimiter(t, o)
	if t == '...' then
		o[#o + 1] = t
	elseif t == ':' then
		o.isMethod = true
	elseif isOp[t] then
		o.op = t
	end
end

function keyword(t, o)
	if t == 'local' then
		o.isLocal = true
	elseif t == 'true' then
		o[#o + 1] = true
	elseif t == 'false' then
		o[#o + 1] = false
	elseif t == 'return' then
		o.stmtType = STMT_TYPE.RETURN
		o.nodeType = NODE_TYPE.STMT
	elseif t == 'nil' then
		o[#o + 1] = NIL
	elseif t == 'break' then
		o.stmtType = STMT_TYPE.BREAK
		o.nodeType = NODE_TYPE.STMT
	elseif t == 'and' or t == 'or' or t == 'not' then
		o.op = t
	end
end

function CHUNK(f, o)
	o.chunk = f{}
end

function LAST_STATEMENT(f, o)
	o[#o + 1] = f{}
end

function UNI_EXP(f, o)
	o[#o + 1] = f{
		valueType = VAL_TYPE.UNI_OP;
		nodeType = NODE_TYPE.EXP;
	}
end

function BIN_EXP(f, o)
	o[#o + 1] = f{
		valueType = VAL_TYPE.BIN_OP;
		nodeType = NODE_TYPE.EXP;
	}
end

function DO(f, o)
	o[#o + 1] = f{}
end

local WHILE_rename = {
	condition = 1;
}
function WHILE(f, o)
	o[#o + 1] = rename(WHILE_rename, f{
		stmtType = STMT_TYPE.WHILE;
		nodeType = NODE_TYPE.STMT;
	})
end

local REPEAT_rename = {
	condition = 1;
}
function REPEAT(f, o)
	o[#o + 1] = rename(REPEAT_rename, f{
		stmtType = STMT_TYPE.REPEAT;
		nodeType = NODE_TYPE.STMT;
	})
end

local IF_rename = {
	condition = 1;
}
function IF(f, o)
	o[#o + 1] = rename(IF_rename, f{
		stmtType = STMT_TYPE.IF;
		nodeType = NODE_TYPE.STMT;
	})
end

function ELSEIF(f, o)
	o[#o + 1] = rename(IF_rename, f{})
end

function ELSE(f, o)
	o[#o + 1] = f{}
end

local FOR_rename = {
	var = 1;
	value = 2;
	stop = 3;
	change = 4;
}

function EXP_LIST(f, o)
	f(o)
end

function FOR(f, o)
	o[#o + 1] = rename(FOR_rename, f{
		stmtType = STMT_TYPE.FOR;
		nodeType = NODE_TYPE.STMT;
	})
end

function VARIABLE_LIST(f, o)
	o.variables = f{}
end

-- Note: additional values in the expression list are allowed
local FOR_GENERIC_rename = {
	iterator = 1;
	state = 2;
	value = 3;
}
function FOR_GENERIC(f, o)
	o[#o + 1] = rename(FOR_GENERIC_rename, f{
		stmtType = STMT_TYPE.FOR_GENERIC;
		nodeType = NODE_TYPE.STMT;
	})
end

local FUNC_rename = {
	name = 1;
	isVararg = 2;
	arguments = 'variables';
}
function LOCAL_FUNC(f, o)
	local func = rename(FUNC_rename, f{
		stmtType = STMT_TYPE.FUNC;
		nodeType = NODE_TYPE.STMT;
	})
	o[#o + 1] = func
end

function FUNC_NAME(f, o)
	o[#o + 1] = f{}
end

function FUNC(f, o)
	local func = rename(FUNC_rename, f{
		stmtType = STMT_TYPE.FUNC;
		nodeType = NODE_TYPE.STMT;
	})
	o[#o + 1] = func
end

local ANON_FUNC_rename = {
	isVararg = 1;
	arguments = 'variables';
}
function ANON_FUNC(f, o)
	o[#o + 1] = rename(ANON_FUNC_rename, f{
		valueType = VAL_TYPE.FUNC;
		nodeType = NODE_TYPE.EXP;
	})
end

function VAR_LIST(f, o)
	o.vars = f{}
end

function LOCAL_DEF(f, o)
	o[#o + 1] = f{
		stmtType = STMT_TYPE.DEF;
		nodeType = NODE_TYPE.STMT;
	}
end

function DEF(f, o)
	o[#o + 1] = f{
		stmtType = STMT_TYPE.DEF;
		nodeType = NODE_TYPE.STMT;
	}
end

function BRACKET_EXP(f, o)
	o[#o + 1] = f{
		isBracket = true;
	}
end

function DOT_INDEX(f, o)
	f(o)
	o[#o] = o[#o].token
end

function VAR(f, o)
	f(o)
end

function CALL_STATEMENT(f, o)
	o[#o + 1] = f{
		stmtType = STMT_TYPE.CALL;
		nodeType = NODE_TYPE.STMT;
	}
end

function CALL_EXP(f, o)
	o[#o + 1] = f{
		valueType = VAL_TYPE.CALL;
		nodeType = NODE_TYPE.EXP;
	}
end

function PREFIX(f, o)
	f(o)
end

function ARGS(f, o)
	o.args = f{}
end

function TABLE(f, o)
	o[#o + 1] = f{
		valueType = VAL_TYPE.TABLE;
		nodeType = NODE_TYPE.EXP;
	}
end

function FIELD(f, o)
	local record = f{}
	if record[2] ~= nil then
		if record[1].isBracket then
			o[record[1][1]] = record[2]
		else
			o[record[1].token] = record[2]
		end
	else
		o[#o + 1] = record[1]
	end
end

return syntax
end