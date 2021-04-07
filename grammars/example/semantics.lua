local syntax = require 'grammars/example/syntax'
syntax:extend()

function number(token, parentRecords)
	parentRecords[#parentRecords + 1] = tonumber(token)
end

function VALUE(records, parentRecords)
	local indexes = {}

	if records[2] then
		for i = records[1], records[2] do
			indexes[i] = true
		end
	else
		indexes[records[1]] = true
	end

	parentRecords.value = indexes
end

function VALUES(records, parentRecords)
	local result

	if records.values then
		result = records.values
		for i in next, records.value do
			result[i] = true
		end
	else
		result = records.value
	end

	parentRecords.values = result
end

function STATEMENT(records, parentRecords)
	parentRecords.at = records[1]
	parentRecords.values = records.values
end

return syntax