local naughty = require("naughty")
local serialize = require("serialize")
local variables = require("variables_base")

local gears = require("gears")

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

local D = {
    debug = 1,
    info = 2,
    warning = 3,
    error = 4,
}

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
    local pid = c.pid or ""
    return c.window .. "[" .. pid .. "] - " .. class
        .. " [" .. instance .. "] - " .. name
end

local log_file = io.open("awesome.log", "a")
local severities = {"D", "I", "W", "E"}
local config = {}

function D.log(severity, message)
    local severity_name = severities[severity]
    if not severity_name then
        return
    end
    if config.log_level > severity then
        return
    end
    log_file:write(os.date("%F %T: ") .. "[" .. severities[severity] .. "] "
        .. tostring(message) .. "\n")
    log_file:flush()
end

local config_file = variables.config_dir .. '/debug.json'

function D.toggle_debug()
    if config.log_level == D.debug then
        config.log_level = D.info
    else
        config.log_level = D.debug
    end
    D.log(D.info, "Log level is now " .. severities[config.log_level])
    serialize.save_to_file(config_file, config)
end

function D.notify_error(args)
    if not args.preset then
        args.preset = naughty.config.presets.critical
    end
    args.destroy = function(reason)
        if reason == naughty.notificationClosedReason.
                dismissedByUser then
            local stream = io.popen("xsel --input --clipboard", "w")
            stream:write(tostring(args.text))
            stream:close()
        end
    end

    naughty.notify(args)
end

if gears.filesystem.file_readable(config_file) then
    config = serialize.load_from_file(config_file)
end
if config.log_level == nil then
    config.log_level = D.info
end

return D
