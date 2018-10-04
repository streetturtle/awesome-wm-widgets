-------------------------------------------------
-- Volume Bar Widget for Awesome Window Manager
-- Shows the current volume level
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/volumebar-widget

-- @author Pavel Makhov
-- @copyright 2018 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local gears = require("gears")
local spawn = require("awful.spawn")
local watch = require("awful.widget.watch")
local wibox = require("wibox")

local GET_VOLUME_CMD = 'amixer -D pulse sget Master'
local INC_VOLUME_CMD = 'amixer -D pulse sset Master 5%+'
local DEC_VOLUME_CMD = 'amixer -D pulse sset Master 5%-'
local TOG_VOLUME_CMD = 'amixer -D pulse sset Master toggle'

local bar_color = "#74aeab"
local mute_color = "#ff0000"
local background_color = "#3a3a3a"

local volumebar_widget = wibox.widget {
    max_value = 1,
    forced_width = 50,
    paddings = 0,
    border_width = 0.5,
    color = bar_color,
    background_color = background_color,
    shape = gears.shape.bar,
    clip = true,
    margins       = {
        top = 10,
        bottom = 10,
    },
    widget = wibox.widget.progressbar
}

local update_graphic = function(widget, stdout, _, _, _)
    local mute = string.match(stdout, "%[(o%D%D?)%]")
    local volume = string.match(stdout, "(%d?%d?%d)%%")
    volume = tonumber(string.format("% 3d", volume))

    widget.value = volume / 100;
    widget.color = mute == "off" and mute_color
                                  or bar_color

end

volumebar_widget:connect_signal("button::press", function(_,_,_,button)
    if (button == 4)     then awful.spawn(INC_VOLUME_CMD)
    elseif (button == 5) then awful.spawn(DEC_VOLUME_CMD)
    elseif (button == 1) then awful.spawn(TOG_VOLUME_CMD)
    end

    spawn.easy_async(GET_VOLUME_CMD, function(stdout, stderr, exitreason, exitcode)
        update_graphic(volumebar_widget, stdout, stderr, exitreason, exitcode)
    end)
end)

watch(GET_VOLUME_CMD, 1, update_graphic, volumebar_widget)

return volumebar_widget