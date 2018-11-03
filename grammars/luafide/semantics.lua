local syntax = require 'grammars/lua/syntax'
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
	o[#o + 1] = t
end

function number(t, o)
	o[#o + 1] = {
		value = t;
		type = 'number';
	}
end

function String(t, o)
	o[#o + 1] = {
		value = t;
		type = 'string';
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
	elseif t == 'return' then
		o.statement = 'RETURN'
	elseif t == 'break' then
		o.statement = 'BREAK'
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

function EXP(f, o)
	f(o)
end

function DO(f, o)
	o[#o + 1] = f{}
end

local WHILE_rename = {
	condition = 1;
}
function WHILE(f, o)
	o[#o + 1] = rename(WHILE_rename, f{
		statement = 'WHILE';
	})
end

local REPEAT_rename = {
	condition = 1;
}
function REPEAT(f, o)
	o[#o + 1] = rename(REPEAT_rename, f{
		statement = 'REPEAT';
	})
end

local IF_rename = {
	condition = 1;
}
function IF(f, o)
	o[#o + 1] = rename(IF_rename, f{
		statement = 'IF';
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
		statement = 'FOR';
	})
end

function VARIABLE_LIST(f, o)
	o.variables = f{}
end


function FOR_GENERIC(f, o)
	o[#o + 1] = f{
		statement = 'FOR_GENERIC';
	}
end

function FUNC_NAME(f, o)
	o.name = f{}
end

local FUNC_rename = {
	name = 1;
	isVararg = 2;
}
function FUNC(f, o)
	o[#o + 1] = rename(FUNC_rename, f{
		statement = 'FUNC';
	})
end

function VAR_LIST(f, o)
	o.vars = f{}
end

function LOCAL_DEF(f, o)
	o[#o + 1] = f{
		statement = 'DEF';
	}
end 

function DEF(f, o)
	o[#o + 1] = f{}
end

function BRACKET_EXP(f, o)
	o[#o + 1] = f{
		isBracket = true;
	}
end

function VAR(f, o)
	f(o)
end

function CALL(f, o)
	o[#o + 1] = f{
		statement = 'CALL';
	}
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
		type = 'table';
		value = {};
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