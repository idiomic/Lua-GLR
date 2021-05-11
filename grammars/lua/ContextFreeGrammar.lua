return function(settings)
local syntax = settings.require('productions/Syntax').define()

local function list(production, sep)
	sep = sep or delimiter[',']
	local name = 'LIST_' .. tostring(production):upper()
	syntax:set(name, sep * production)
	return production * syntax:get(name)'*'
end

local function parens(production)
	return delimiter['('] * production * delimiter[')']
end

local OPT_CHUNK = CHUNK'?'

START = OPT_CHUNK * eof

STATEMENT = (BRANCH + ASSIGN + CALL) * delimiter[';']'?'

BRANCH = DO
	+ WHILE
	+ REPEAT
	+ IF
	+ FOR
	+ FOR_GENERIC

ASSIGN = FUNC
	+ LOCAL_FUNC
	+ LOCAL_DEF
	+ DEF

CHUNK = STATEMENT'*' * LAST_STATEMENT'?'

EXP = keyword['nil']
	+ keyword['false']
	+ keyword['true']
	+ decimal
	+ hexadecimal
	+ String
	+ delimiter['...']
	+ ANON_FUNC
	+ PREFIX
	+ TABLE
	+ UNI_EXP
	+ BIN_EXP

UNARY_OP = delimiter['-']
	+ keyword['not']
	+ delimiter['#']

UNI_EXP = UNARY_OP * EXP

BINARY_OP = delimiter['+']
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

LAST_STATEMENT = keyword['return'] * EXP_LIST'?'
	+ keyword['break']

DO_CHUNK = keyword['do'] * OPT_CHUNK * keyword['end']

DO = DO_CHUNK

CONDITION = EXP

WHILE = keyword['while'] * CONDITION * DO_CHUNK

REPEAT = keyword['repeat'] * OPT_CHUNK * keyword['until'] * CONDITION

IF = keyword['if'] * CONDITION * keyword['then'] * OPT_CHUNK
	* ELSEIF'*' * ELSE'?' * keyword['end']
ELSEIF = keyword['elseif'] * CONDITION * keyword['then'] * OPT_CHUNK

ELSE = keyword['else'] * OPT_CHUNK

FOR = keyword['for'] * variable * delimiter['='] * EXP_LIST * DO_CHUNK

VARIABLE_LIST = list(variable)

FOR_GENERIC = keyword['for'] * VARIABLE_LIST * keyword['in'] * EXP_LIST * DO_CHUNK
 
PARAMS = VARIABLE_LIST
	+ VARIABLE_LIST * delimiter[','] * delimiter['...']
	+ delimiter['...']

FUNC_BODY = parens(PARAMS'?') * OPT_CHUNK * keyword['end']

METHOD = delimiter[':'] * variable

DOT_INDEX = delimiter['.'] * variable

FUNC_NAME = variable * DOT_INDEX'*' * METHOD'?'

FUNC = keyword['function'] * FUNC_NAME * FUNC_BODY
	
LOCAL_FUNC = keyword['local'] * keyword['function'] * variable * FUNC_BODY

LOCAL_DEF = keyword['local'] * (
	VARIABLE_LIST +
	VARIABLE_LIST * delimiter['='] * EXP_LIST )

VAR_LIST = list(VAR)

DEF = VAR_LIST * delimiter['='] * EXP_LIST

BRACKET_EXP = delimiter['['] * EXP * delimiter[']']

VAR = variable
	+ PREFIX * (BRACKET_EXP + DOT_INDEX)

CALL = PREFIX * METHOD'?' * ARGS

PREFIX = VAR + CALL + parens(EXP)

ARGS = parens(EXP_LIST'?') + TABLE + String

FIELD_SEP = delimiter[','] + delimiter[';']

FIELD_LIST = list(FIELD, FIELD_SEP) * FIELD_SEP'?'

TABLE = delimiter['{'] * FIELD_LIST'?' * delimiter['}']

NAMED_FIELD = BRACKET_EXP * delimiter['='] * EXP
	+ variable * delimiter['='] * EXP

FIELD = NAMED_FIELD
	+ EXP
	
ANON_FUNC = keyword['function'] * FUNC_BODY

return syntax
end