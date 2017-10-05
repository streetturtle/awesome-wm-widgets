local awful = require("awful")
local spawn = require("awful.spawn")
local watch = require("awful.widget.watch")
local wibox = require("wibox")

local request_command = 'amixer -D pulse sget Master'
local bar_color = "#74aeab"
local mute_color = "#ff0000"

volumearc_widget = wibox.widget {
--    {
--        id = "txt",
--        text = "1",
--        font = "Play 5",
--        widget = wibox.widget.textbox
--    },
    max_value = 1,
    rounded_edge = true,
    thickness = 2,
    start_angle = 4.71238898, -- 2pi*3/4
    forced_height = 16,
    forced_width = 16,
    bg = "#ffffff11",
    paddings = 2,
    widget = wibox.container.arcchart,
    set_value = function(self, value)
        self.value = value
    end,
}

local update_graphic = function(widget, stdout, _, _, _)
    local mute = string.match(stdout, "%[(o%D%D?)%]")
    local volume = string.match(stdout, "(%d?%d?%d)%%")
    volume = tonumber(string.format("% 3d", volume))

    widget.value = volume / 100;
--    widget.txt.text = volume;
    if mute == "off" then
        widget.colors = { mute_color }
    else
        widget.colors = { bar_color }
    end
end

volumearc_widget:connect_signal("button::press", function(_, _, _, button)
    if (button == 4) then awful.spawn("amixer -D pulse sset Master 5%+", false)
    elseif (button == 5) then awful.spawn("amixer -D pulse sset Master 5%-", false)
    elseif (button == 1) then awful.spawn("amixer -D pulse sset Master toggle", false)
    end

    spawn.easy_async(request_command, function(stdout, stderr, exitreason, exitcode)
        update_graphic(volumearc_widget, stdout, stderr, exitreason, exitcode)
    end)
end)

watch(request_command, 1, update_graphic, volumearc_widget)
