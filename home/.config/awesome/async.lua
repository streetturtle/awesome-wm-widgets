local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")

local debug_util = require("debug_util")

local async = {}

function async.safe_call(action)
    local result, err = xpcall(action, debug.traceback)
    if not result then
        naughty.notify({
                preset=naughty.config.presets.critical,
                title="Error", text=err})
    end
end

local function handle_start_command(command, action)
    local result = action()
    if type(action) == "string" then
        naughty.notify({
                preset=naughty.config.presets.critical,
                title="Error starting command: " .. command,
                text=result})
    else
        return result
    end
end

function async.spawn_and_get_output(command, callback)
    local command_str = debug_util.to_string_recursive(command)
    return handle_start_command(command_str, function()
        return awful.spawn.easy_async(command,
                function(stdout, stderr, _, exit_code)
                    local result = nil
                    async.safe_call(
                            function()
                                result = callback(stdout, exit_code)
                            end)
                    if not result and exit_code ~= 0 then
                        naughty.notify({
                                preset=naughty.config.presets.critical,
                                title="Error running command: " .. command_str,
                                text=stderr})
                    end
                end)
    end)
end

function async.spawn_and_get_lines(command, callback, finish_callback,
        done_callback)
    local log = {stderr=""}
    local done = nil
    if done_callback then
        done =
            function(line)
                async.safe_call(function() done_callback(line) end)
            end
    end
    local command_str = debug_util.to_string_recursive(command)
    return handle_start_command(command_str, function()
        return awful.spawn.with_line_callback(command, {
                stdout=function(line)
                    async.safe_call(function() callback(line) end)
                end,
                stderr=function(line)
                    log.stderr = log.stderr .. line .. "\n"
                end,
                exit=function(_, code)
                    local result = nil
                    if finish_callback then
                        result = finish_callback(code)
                    end
                    if not result and code ~= 0 then
                        naughty.notify({
                                preset=naughty.config.presets.critical,
                                title="Error running command: " .. command_str,
                                text=log.stderr})
                    end
                end,
                output_done=done})
    end)
end

function async.run_continuously(action)
    local retries = 0
    local timer = gears.timer({
            timeout=1,
            single_shot=true,
            callback=function()
                retries = 0
            end})
    local start
    local function callback()
        if retries < 3 then
            retries = retries + 1
            start()
            return true
        end
        debug_util.log("Too many retries, giving up.")
        return false
    end
    start = function()
        action(callback)
        timer:again()
    end
    start()
end

function async.run_command_continuously(command, line_callback, start_callback,
        finish_callback)
    if not line_callback then
        line_callback = function() end
    end
    if not finish_callback then
        finish_callback = function() return false end
    end
    local command_str = debug_util.to_string_recursive(command)
    async.run_continuously(
            function(callback)
                debug_util.log("Running command: " .. command_str)
                local pid = async.spawn_and_get_lines(command, line_callback,
                        function()
                            debug_util.log("Command stopped: " .. command_str)
                            if not finish_callback() then
                                return callback()
                            end
                            return true
                        end)
                if pid then
                    if start_callback then
                        start_callback(pid)
                    end
                else
                    if not finish_callback() then
                        callback()
                    end
                end
            end)
end

function async.run_commands(commands)
    for _, command in ipairs(commands) do
        async.spawn_and_get_output(command, function() end)
    end
end

return async
