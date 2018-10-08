-------------------------------------------------
-- Brightness Widget for Awesome Window Manager
-- Shows the brightness level of the laptop display
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/brightness-widget

-- @author Pavel Makhov
-- @copyright 2017 Pavel Makhov
-------------------------------------------------

local wibox = require("wibox")
local watch = require("awful.widget.watch")
local spawn = require("awful.spawn")

local PATH_TO_ICON = "/usr/share/icons/Arc/status/symbolic/display-brightness-symbolic.svg"
local GET_BRIGHTNESS_CMD = "light -G"   -- "xbacklight -get"
local INC_BRIGHTNESS_CMD = "light -A 1" -- "xbacklight -inc 5"
local DEC_BRIGHTNESS_CMD = "light -U 1" -- "xbacklight -dec 5"

local brightness_text = wibox.widget.textbox()
brightness_text:set_font('Play 9')

local brightness_icon = wibox.widget {
    {
    	image = PATH_TO_ICON,
    	resize = false,
        widget = wibox.widget.imagebox,
    },
    top = 3,
    widget = wibox.container.margin
}

local brightness_widget = wibox.widget {
    brightness_icon,
    brightness_text,
    layout = wibox.layout.fixed.horizontal,
}

local update_widget = function(widget, stdout, stderr, exitreason, exitcode)
    local brightness_level = tonumber(string.format("%.0f", stdout))
    widget:set_text(" " .. brightness_level .. "%")
end,

brightness_widget:connect_signal("button::press", function(_,_,_,button)
    if (button == 4)     then spawn(INC_BRIGHTNESS_CMD, false)
    elseif (button == 5) then spawn(DEC_BRIGHTNESS_CMD, false)
    end

    spawn.easy_async(GET_BRIGHTNESS_CMD, function(stdout, stderr, exitreason, exitcode)
        update_widget(brightness_widget, stdout, stderr, exitreason, exitcode)
    end)
end)

watch(GET_BRIGHTNESS_CMD, 1, update_widget, brightness_text)

return brightness_widget
