return function(settings)
local syntax = settings.require('productions/Syntax').define()

local e

START = TABLE * eof

local FIELD_SEP = delimiter[','] + delimiter[';']

TABLE = delimiter['{'] * (FIELD_LIST + e) * (FIELD_SEP + e) * delimiter['}']

FIELD_LIST = FIELD + FIELD * FIELD_SEP * FIELD_LIST

FIELD = VALUE
	+ KEY * delimiter['='] * VALUE

KEY = variable
	+ delimiter['['] * VALUE * delimiter[']']

VALUE = keyword['nil']
	+ keyword['true']
	+ keyword['false']
	+ number
	+ delimiter['-'] * number
	+ String
	+ TABLE

return syntax
end