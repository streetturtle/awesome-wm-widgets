local awful = require("awful")
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
    critical = 5,
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

log_file_name = "awesome.log"
debug_file_name = "awesome.debug.log"
local severities = {"D", "I", "W", "E", "C"}
local cleanup_script = variables.config_dir .. "/logfile-cleanup"
local archive_script = variables.config_dir .. "/logfile-archive"

function D.log(severity, message)
    local severity_name = severities[severity]
    if not severity_name then
        return
    end
    local log_str = os.date("%F %T: ") .. "[" .. severities[severity] .. "] "
        .. tostring(message) .. "\n"
    if severity >= D.info then
        local log_file = io.open(log_file_name, "a")
        log_file:write(log_str)
        log_file:flush()
    end
    local debug_file = io.open(debug_file_name, "a")
    debug_file:write(log_str)
    debug_file:flush()
    if severity >= D.critical then
        awful.spawn({archive_script, debug_file_name})
    end
    awful.spawn({cleanup_script, debug_file_name, "10000"})
    awful.spawn({cleanup_script, log_file_name, "10000"})
end

function D.notify_error(args)
    D.log(D.error, args.text)
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

return D
