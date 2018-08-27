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

function tables.concatenate(t, separator)
    if not separator then
        separator = " "
    end
    if type(t) == "table" then
        result = ""
        for _, x in ipairs(t) do
            result = result .. tables.concatenate(x, separator) .. separator
        end
        return result
    elseif type(t) == "string" then
        return t
    else
        return tostring(x)
    end
end

return tables
