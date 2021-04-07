local syntax = require('Syntax').define()

-- Required augmentation so the parser knows where to start
START = STATEMENT * eof

-- lowercase variables corrispond to token types
-- indexing a token type requires a specific token of that type
STATEMENT = keyword.select * VALUES * keyword.at * number

-- 'and' is a Lua keyword, so we need to use a string instead
VALUES = VALUE * keyword['and'] * VALUES + VALUE

-- addition is or's productions, multiplication and's them
VALUE = number + number * keyword.thru * number

return syntax