return function(settings)

local semantics = settings.require 'grammars/tableParser/syntax'
semantics:extend()

function variable(t, o)
	o.value = t
end

function String(t, o)
	o.value = t
end

function number(t, o)
	if o.isNegative then
		o.value = -tonumber(t)
	else
		o.value = tonumber(t)
	end
end

function keyword(t, o)
	o.value = t == 'true' and true
		or t == 'false' and false
		or nil
end

function delimiter(t, o)
	if t == '-' then
		o.isNegative = true
	end
end

function TABLE(f, o)
	o.value = f{}
end

function KEY(f, o)
	local key = f{}
	o.key = key.value
end

function VALUE(f, o)
	local value = f{}
	o.value = value.value
end

function FIELD(f, o)
	local field = f{}
	if field.key then
		o[field.key] = field.value
	else
		o[#o + 1] = field.value
	end
end

function FIELD_LIST(f, o)
	f(o)
end

return semantics
end