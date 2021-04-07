return function (input)
    local literals = {}
    local types = {}

    for token in input:gmatch '%w+' do
        local i = #literals + 1
        literals[i] = token
        types[i] = token:match '^%d+$' and 'number' or 'keyword'
    end

    local lastI = #literals + 1
    literals[lastI] = ''
    types[lastI] = 'eof'

    return {
        literals = literals;
        types = types;
    }
end