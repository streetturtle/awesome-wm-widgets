local utils = {}


function utils.trim(str)
    return string.match(str, "^%s*(.-)%s*$")
end

function utils.split(string_to_split, separator)
    if separator == nil then separator = "%s" end
    local t = {}

    for str in string.gmatch(string_to_split, "([^".. separator .."]+)") do
        table.insert(t, str)
    end

    return t
end

function utils.popen_and_return(cmd)
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()

    return result
end


return utils
