local awful = require("awful")
local async = require("async")

local util = {}

function util.start_if_not_running(command, args)
    async.spawn_and_get_output("pidof -x " .. command,
            function(stdout, result_code)
                if result_code ~= 0 then
                    awful.spawn(command .. " " .. args)
                    return true
                end
            end)
end

function util.get_available_command(commands)
    for _, command in ipairs(commands) do
        local args = ""
        if command.args then
            args = command.args
        end
        local test
        local command_base = command.command .. " "
        if command.test then
            test = command.test
        else
            local test_args = "--help"
            if command.test_args then
                test_args = command.test_args
            end
            test = command_base .. test_args
        end
        if os.execute(test) then
            return command_base .. args
        end
    end
    return nil
end

return util
