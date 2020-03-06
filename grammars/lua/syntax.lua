return function(settings)
local syntax = settings.require('productions/Syntax').define()

local function list(production, sep)
	return production * ((sep or delimiter[',']) * production) '*'
end

local function parens(production)
	return delimiter['('] * production * delimiter[')']
end

local e

START = CHUNK * eof

local STATEMENT = DO
	+ WHILE
	+ REPEAT
	+ IF
	+ FOR
	+ FOR_GENERIC
	+ FUNC
	+ LOCAL_FUNC
	+ LOCAL_DEF
	+ DEF
	+ CALL_STATEMENT

CHUNK = STATEMENT '*' * (LAST_STATEMENT + e)

local OPT_CHUNK = CHUNK + e

local EXP = keyword['nil']
	+ keyword['false']
	+ keyword['true']
	+ number
	+ String
	+ delimiter['...']
	+ ANON_FUNC
	+ PREFIX
	+ TABLE
	+ UNI_EXP
	+ BIN_EXP

local OP = delimiter['-']
	+ keyword['not']
	+ delimiter['#']

UNI_EXP = OP * EXP

local BINARY_OP = delimiter['+']
	+ delimiter['-']
	+ delimiter['*']
	+ delimiter['/']
	+ delimiter['^']
	+ delimiter['%']
	+ delimiter['..']
	+ delimiter['<']
	+ delimiter['<=']
	+ delimiter['>']
	+ delimiter['>=']
	+ delimiter['==']
	+ delimiter['~=']
	+ keyword['and']
	+ keyword['or']

BIN_EXP = EXP * BINARY_OP * EXP

EXP_LIST = list(EXP)

local OPT_EXP_LIST = EXP_LIST + e

LAST_STATEMENT = keyword['return'] * OPT_EXP_LIST
	+ keyword['break']

local DO_CHUNK = keyword['do'] * OPT_CHUNK * keyword['end']

DO = DO_CHUNK

WHILE = keyword['while'] * EXP * DO_CHUNK

REPEAT = keyword['repeat'] * OPT_CHUNK * keyword['until'] * EXP

IF = keyword['if'] * EXP * keyword['then'] * OPT_CHUNK
	* ELSEIF '*' * (ELSE + e) * keyword['end']

ELSEIF = keyword['elseif'] * EXP * keyword['then'] * OPT_CHUNK

ELSE = keyword['else'] * OPT_CHUNK

FOR = keyword['for'] * variable * delimiter['='] * EXP_LIST * DO_CHUNK

VARIABLE_LIST = list(variable)

FOR_GENERIC = keyword['for'] * VARIABLE_LIST * keyword['in'] * EXP_LIST * DO_CHUNK

local PARAMS = VARIABLE_LIST * (delimiter[','] * delimiter['...'] + e)
	+ delimiter['...']
	+ e

local FUNC_BODY = parens(PARAMS) * OPT_CHUNK * keyword['end']

local METHOD = delimiter[':'] * variable + e

DOT_INDEX = delimiter['.'] * variable

FUNC_NAME = variable * DOT_INDEX '*' * METHOD

FUNC = keyword['function'] * FUNC_NAME * FUNC_BODY
	
LOCAL_FUNC = keyword['local'] * keyword['function'] * variable * FUNC_BODY

LOCAL_DEF = keyword['local'] * VARIABLE_LIST * (delimiter['='] * EXP_LIST + e)

VAR_LIST = list(VAR)

DEF = VAR_LIST * delimiter['='] * EXP_LIST

BRACKET_EXP = delimiter['['] * EXP * delimiter[']']

VAR = variable
	+ PREFIX * (BRACKET_EXP + DOT_INDEX)

local CALL = PREFIX * METHOD * ARGS

CALL_EXP = CALL

CALL_STATEMENT = CALL

PREFIX = VAR + CALL_EXP + parens(EXP)

ARGS = parens(OPT_EXP_LIST) + TABLE + String

local FIELD_SEP = delimiter[','] + delimiter[';']

local FIELD_LIST = list(FIELD, FIELD_SEP) * (FIELD_SEP + e)

TABLE = delimiter['{'] * (FIELD_LIST + e) * delimiter['}']

FIELD = BRACKET_EXP * delimiter['='] * EXP
	+ variable * delimiter['='] * EXP
	+ EXP
	
ANON_FUNC = keyword['function'] * FUNC_BODY

return syntax
end