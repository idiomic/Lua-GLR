local syntax = require('Syntax').define()

local function list(production, sep)
	return production * ((sep or delimiter[',']) * production) '*'
end

local function parens(production)
	return delimiter['('] * production * delimiter[')']
end

local E = e '?'

START = CHUNK * eof

local STATEMENT = DO
	+ WHILE
	+ REPEAT
	+ IF
	+ FOR
	+ FOR_GENERIC
	+ FUNC
	+ LOCAL_DEF
	+ DEF
	+ CALL

CHUNK = list(STATEMENT, delimiter[';']) '*'
		* (LAST_STATEMENT * (delimiter[';'] + E) + E)

EXP_LIST = list(EXP)

local OPT_EXP_LIST = EXP_LIST + E

LAST_STATEMENT = keyword['return'] * OPT_EXP_LIST
	+ keyword['break']

local DO_CHUNK = keyword['do'] * CHUNK * keyword['end']

DO = DO_CHUNK

WHILE = keyword['while'] * EXP * DO_CHUNK

REPEAT = keyword['repeat'] * CHUNK * keyword['until'] * EXP

IF = keyword['if'] * EXP * keyword['then'] * CHUNK
		* ELSEIF '*' * ELSE * keyword['end']

ELSEIF = keyword['elseif'] * EXP * keyword['then'] * CHUNK

ELSE = keyword['else'] * CHUNK + E

FOR = keyword['for'] * variable * delimiter['='] * EXP_LIST * DO_CHUNK

VARIABLE_LIST = list(variable)

FOR_GENERIC = keyword['for'] * VARIABLE_LIST * keyword['in'] * EXP_LIST * DO_CHUNK

local PARAMS = VARIABLE_LIST * (delimiter[','] * delimiter['...'] + E)
	+ delimiter['...']
	+ E

local FUNC_BODY = parens(PARAMS) * CHUNK * keyword['end']

local METHOD = delimiter[':'] * variable + E

local DOT_INDEX = delimiter['.'] * variable

FUNC_NAME = variable * DOT_INDEX '*' * METHOD

FUNC = (keyword['local'] * keyword['function'] * variable
		+ keyword['function'] * FUNC_NAME)
	* FUNC_BODY

LOCAL_DEF = keyword['local'] * VARIABLE_LIST * (delimiter['='] * EXP_LIST + E)

VAR_LIST = list(VAR)

DEF = VAR_LIST * delimiter['='] * EXP_LIST

BRACKET_EXP = delimiter['['] * EXP * delimiter[']']

VAR = variable
	+ PREFIX * (BRACKET_EXP + DOT_INDEX)

CALL = PREFIX * METHOD * ARGS

PREFIX = VAR + CALL + parens(EXP)

ARGS = parens(OPT_EXP_LIST) + TABLE + String

local FIELD_SEP = delimiter[','] + delimiter[';']

local FIELD_LIST = list(FIELD, FIELD_SEP) * (FIELD_SEP + E)

TABLE = delimiter['{'] * (FIELD_LIST + E) * delimiter['}']

FIELD = BRACKET_EXP * delimiter['='] * EXP
	+ variable * delimiter['='] * EXP
	+ EXP

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

local OP = delimiter['-']
	+ keyword['not']
	+ delimiter['#']

EXP = keyword['nil']
	+ keyword['false']
	+ keyword['true']
	+ number
	+ String
	+ delimiter['...']
	+ keyword['function'] * FUNC_BODY
	+ PREFIX
	+ TABLE
	+ EXP * BINARY_OP * EXP
	+ OP * EXP

return syntax