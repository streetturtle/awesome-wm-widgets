local awful = require("awful")

local function start_if_not_running(command, args)
    awful.spawn.with_shell("if ! pidof -x " .. command .. "; then " .. command
            .. " " .. args .. "; fi")
end

return {
    start_if_not_running=start_if_not_running
}
