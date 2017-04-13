local function __to_string_recursive(object, depth)
    if type(object) == "table" then
       local prefix = ""
       for _=1,depth do
           prefix = prefix .. " "
       end
       local result = "{\n"
       for key, value in pairs(object) do
           result = result .. prefix .. " "
                   .. __to_string_recursive(key, depth + 1) .. " -> "
                   .. __to_string_recursive(value, depth + 1) .. "\n"
       end
       return result .. prefix .. "}"
    elseif type(object) == "string" then
        return "\"" .. object .. "\""
    else
       return tostring(object)
    end
end

local function to_string_recursive(object)
    return __to_string_recursive(object, 0)
end

return {to_string_recursive=to_string_recursive}
