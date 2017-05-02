local awful = require("awful")
local naughty = require("naughty")

local function safe_call(action)
    local result, err = xpcall(action, debug.traceback)
    if not result then
        naughty.notify({
                preset=naughty.config.presets.critical,
                title="Error", text=err})
    end
end

local function spawn_and_get_output(command, callback)
    awful.spawn.easy_async(command,
            function(stdout, stderr, _, exit_code)
                if exit_code ~= 0 then
                    naughty.notify({
                            preset=naughty.config.presets.critical,
                            title="Error running command: " .. command,
                            text=stderr})
                end
                safe_call(function() callback(stdout) end)
            end)
end

local function spawn_and_get_lines(command, callback)
    local log = {stderr=""}
    awful.spawn.with_line_callback(command, {
            stdout=function(line) safe_call(function() callback(line) end) end,
            stderr=function(line)
                log.stderr = log.stderr .. line .. "\n"
            end,
            exit=function(_, code)
                if code ~= 0 then
                    naughty.notify({
                            preset=naughty.config.presets.critical,
                            title="Error running command: " .. command,
                            text=log.stderr})
                end
            end})
end

return {
    safe_call=safe_call,
    spawn_and_get_output=spawn_and_get_output,
    spawn_and_get_lines=spawn_and_get_lines,
}
