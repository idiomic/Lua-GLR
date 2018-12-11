local VAL_TYPE = {}
local NODE_TYPE = {}
local STMT_TYPE = {}

return function(settings)
	
local denseMT = {
	__index = settings.require 'grammars/luafide/env/denseIndex';
}
setmetatable(VAL_TYPE, denseMT)
setmetatable(NODE_TYPE, denseMT)
setmetatable(STMT_TYPE, denseMT)

local syntax = settings.require 'grammars/lua/syntax'
syntax:extend()

local block = {}
local refs = {}

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
	if not block[t] then
		block[t] = {
			defined = false;
			valueType = VAL_TYPE.UNKNOWN;
			nodeType = NODE_TYPE.REF;
			value = nil;
			token = t;
		}
	end
	o[#o + 1] = block[t]
end

function number(t, o)
	o[#o + 1] = {
		value = t;
		valueType = VAL_TYPE.NUMBER;
		nodeType = NODE_TYPE.VALUE;
	}
end

function String(t, o)
	o[#o + 1] = {
		value = t;
		valueType = VAL_TYPE.STRING;
		nodeType = NODE_TYPE.VALUE;
	}
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
		o[#o + 1] = {
			value = true;
			valueType = VAL_TYPE.BOOL;
			nodeType = NODE_TYPE.VALUE;
		}
	elseif t == 'false' then
		o[#o + 1] = {
			value = false;
			valueType = VAL_TYPE.BOOL;
			nodeType = NODE_TYPE.VALUE;
		}
	elseif t == 'return' then
		o.stmtType = STMT_TYPE.RETURN
		o.nodeType = NODE_TYPE.STMT
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
	o[#o + 1] = f{}
end

function BIN_EXP(f, o)
	o[#o + 1] = f{}
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
}

function EXP_LIST(f, o)
	o.exps = f{}
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


function FOR_GENERIC(f, o)
	o[#o + 1] = f{
		stmtType = STMT_TYPE.FOR_GENERIC;
		nodeType = NODE_TYPE.STMT;
	}
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
	local ref = func.name
	ref.valueType = VAL_TYPE.FUNC
	ref.value = func
	ref.defined = true
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
	local ref = func.name[#func.name]
	ref.valueType = VAL_TYPE.FUNC
	ref.value = func
	ref.defined = true
	o[#o + 1] = func
end

local ANON_FUNC_rename = {
	isVararg = 1;
	arguments = 'variables';
}
function ANON_FUNC(f, o)
	o[#o + 1] = rename(ANON_FUNC_rename, f{
		valueType = VAL_TYPE.FUNC;
		nodeType = NODE_TYPE.VALUE;
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
	o[#o + 1] = f{}
end

function PREFIX(f, o)
	f(o)
end

function ARGS(f, o)
	local key, value = next(f{})
	o.args = value
end

function TABLE(f, o)
	o[#o + 1] = f{
		value = {};
		valueType = VAL_TYPE.TABLE;
		nodeType = NODE_TYPE.VALUE;
	}
end

function FIELD(f, o)
	local record = f{}
	if record[2] then
		o.value[record[1]] = record[2]
	else
		o.value[#o.value + 1] = record[1]
	end
end

return syntax
end