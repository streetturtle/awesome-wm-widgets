local tables = {}

function tables.is_empty(t)
    for k, v in pairs(t) do
        return false
    end
    return true
end

function tables.get(t, key, default)
    if t[key] == nil then
        if default == nil then
            t[key] = {}
        else
            t[key] = default
        end
    end
    return t[key]
end

return tables
