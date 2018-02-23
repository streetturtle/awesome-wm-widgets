local awful = require("awful")

local util = {}

function util.start_if_not_running(command, args)
    awful.spawn.with_shell("if ! pidof -x " .. command .. "; then " .. command
            .. " " .. args .. "; fi")
end

function util.get_available_command(commands)
    for _, command in ipairs(commands) do
        local args = ""
        if command.args then
            args = command.args
        end
        local test_args = "--help"
        if command.test_args then
            test_args = command.test_args
        end
        local command_base = command.command .. " "
        if os.execute(command_base .. test_args) then
            return command_base .. args
        end
    end
    return nil
end

return util
