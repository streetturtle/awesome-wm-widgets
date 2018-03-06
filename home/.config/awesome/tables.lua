local tables = {}

function tables.is_empty(t)
    for k, v in pairs(t) do
        return false
    end
    return true
end

return tables
