local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local wibox = require("wibox")

local async = require("async")
local command = require("command")
local D = require("debug_util")
local variables = require("variables")

local tresorit = {}

local tresorit_command = command.get_available_command({
    {command="tresorit-cli", test="tresorit-cli status"}
})

local has_error = false

local function call_tresorit_cli(command, callback)
    local result = {}
    async.spawn_and_get_lines(tresorit_command .. " --porcelain " .. command,
        function(line)
            table.insert(result, gears.string.split(line, "\t"))
        end,
        function()
            return has_error
        end,
        function()
            if callback then
                has_error = callback(result)
            end
        end)
end

local menu_widget = awful.widget.launcher{
    image=variables.config_dir .. "/tresorit.png",
    menu=awful.menu{items={
        {"Start", function() call_tresorit_cli("start") end},
        {"Stop", function() call_tresorit_cli("stop") end},
        {"Logout", function() call_tresorit_cli("logout") end},
        {"Open GUI", function() awful.spawn("tresorit") end},
    }}
}

local stopped_widget = wibox.widget{
    image=variables.config_dir .. "/cancel.svg",
    resize=true,
    widget=wibox.widget.imagebox,
}

local logout_widget = wibox.widget{
    image=variables.config_dir .. "/question.svg",
    resize=true,
    widget=wibox.widget.imagebox,
}

local error_widget = wibox.widget{
    image=variables.config_dir .. "/exclamation-red.svg",
    resize=true,
    widget=wibox.widget.imagebox,
}

tresorit.widget = wibox.widget{
    menu_widget,
    logout_widget,
    stopped_widget,
    error_widget,
    layout=wibox.layout.stack,
    visible=tresorit_command ~= nil
}

local tooltip = awful.tooltip{
    objects={tresorit.widget},
    text="-"
}

if tresorit_command ~= nil then
    D.log("Has tresorit-cli")
    local timer
    timer = gears.timer{
        timeout=2,
        single_shot=true,
        call_now=true,
        autostart=true,
        callback=function()
            D.log("Tresorit: check status")
            call_tresorit_cli("status",
                function(result)
                    D.log(D.to_string_recursive(result))
                    local running = false
                    local logged_in = false
                    local error_code = nil
                    local description = nil
                    for _, line in ipairs(result) do
                        if line[1] == "Tresorit daemon:" then
                            running = line[2] == "running"
                        elseif line[1] == "Logged in as:" then
                            logged_in = line[2] ~= "-"
                            tooltip.text = line[2]
                        elseif line[1] == "Error code:" then
                            error_code = line[2]
                        elseif line[1] == "Description:" then
                            description = line[2]
                        end
                    end
                    error = false
                    if error_code then
                        tooltip.text = error_code .. ": " .. description
                        error = true
                    end
                    D.log("Tresorit: running=" .. tostring(running)
                        .. " logged_in=" .. tostring(logged_in)
                        .. " error=" .. tostring(error))
                    stopped_widget.visible = not error and not running
                    logout_widget.visible = running and not logged_in
                    error_widget.visible = error
                    timer:start()
                    return error
                end)
        end}

    call_tresorit_cli("start")
else
    D.log("No tresorit-cli")
end

return tresorit
