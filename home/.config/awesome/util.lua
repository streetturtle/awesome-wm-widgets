local awful = require("awful")

local function start_if_not_running(command, args)
    awful.spawn.with_shell("if ! pidof -x " .. command .. "; then " .. command
            .. " " .. args .. "; fi")
end

local function get_available_command(commands)
    for _, command in ipairs(commands) do
        if os.execute(command .. " --help") then
            return command
        end
    end
    return nil
end

return {
    start_if_not_running=start_if_not_running,
    get_available_command=get_available_command,
}
