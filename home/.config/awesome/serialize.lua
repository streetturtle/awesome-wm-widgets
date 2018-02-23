local json = require("json/json")

local serialize = {}

function serialize.save_to_file(filename, object)
    local content = json.encode(object)
    local f = io.open(filename, "w")
    f:write(content)
    f:close()
end

function serialize.load_from_file(filename)
    local f = io.open(filename, "r")
    local content = f:read("*a")
    local result = json.decode(content)
    f:close()
    return result
end

return serialize
