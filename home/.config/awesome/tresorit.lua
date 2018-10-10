local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local wibox = require("wibox")

local async = require("async")
local command = require("command")
local variables = require("variables")

local tresorit = {}

local tresorit_command = command.get_available_command({
    {command="tresorit-cli", test="tresorit-cli status"}
})

local function call_tresorit_cli(command, callback)
    local result = {}
    async.spawn_and_get_lines(tresorit_command .. " --porcelain " .. command,
        function(line) table.insert(result, gears.string.split(line, "\t")) end,
        nil,
        function()
            if callback then
                callback(result)
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

tresorit.widget = wibox.widget{
    menu_widget,
    logout_widget,
    stopped_widget,
    layout=wibox.layout.stack,
    visible=tresorit_command ~= nil
}

local tooltip = awful.tooltip{
    objects={tresorit.widget},
    text="-"
}

if tresorit_command ~= nil then
    local timer
    timer = gears.timer{
        timeout=2,
        single_shot=true,
        call_now=true,
        autostart=true,
        callback=function()
            debug_util.log("Tresorit: check status")
            call_tresorit_cli("status",
                function(result)
                    debug_util.log(debug_util.to_string_recursive(result))
                    local running = false
                    local logged_in = false
                    for _, line in ipairs(result) do
                        if line[1] == "Tresorit daemon:" then
                            running = line[2] == "running"
                        elseif line[1] == "Logged in as:" then
                            logged_in = line[2] ~= "-"
                            tooltip.text = line[2]
                        end
                    end
                    debug_util.log("Tresorit: running=" .. tostring(running)
                        .. " logged_in=" .. tostring(logged_in))
                    stopped_widget.visible = not running
                    logout_widget.visible = running and not logged_in
                    timer:start()
                end)
        end}

    call_tresorit_cli("start")
end

return tresorit
