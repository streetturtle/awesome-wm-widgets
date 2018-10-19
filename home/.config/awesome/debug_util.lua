local function __to_string_recursive(object, depth, index, found)
    if type(object) == "table" then
        local id = tostring(depth) .. "." .. tostring(index)
        print(found[object])
        if found[object] then
            return "<" .. found[object] .. ">"
        end
        found[object] = id

        local prefix = ""
        for _=1,depth do
            prefix = prefix .. " "
        end
        local result = "<" .. id .. ">{\n"
        local n = 0
        for key, value in pairs(object) do
            result = result .. prefix .. " "
                    .. __to_string_recursive(key, depth + 1, n, found) .. " -> "
                    .. __to_string_recursive(value, depth + 1, n, found) .. "\n"
            n = n + 1
        end
        return result .. prefix .. "}"
    elseif type(object) == "string" then
        return "\"" .. object .. "\""
    else
       return tostring(object)
    end
end

local D = {}

function D.to_string_recursive(object)
    return __to_string_recursive(object, 0, 0, {})
end

function D.print_property(obj, property)
    return property .. "=" .. D.to_string_recursive(obj[property])
end

function D.get_client_debug_info(c)
    if not c then
        return "<none>"
    end
    local class = c.class or ""
    local name = c.name or ""
    local instance = c.instance or ""
    return c.window .. " - " .. class .. " [" .. instance .. "] - " .. name
end

local log_file = io.open("awesome.log", "a")

function D.log(message)
    log_file:write(os.date("%F %T: ") .. message .. "\n")
    log_file:flush()
end

return D
