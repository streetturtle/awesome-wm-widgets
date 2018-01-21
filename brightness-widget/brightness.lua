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

--local GET_BRIGHTNESS_CMD = "xbacklight -get"
local GET_BRIGHTNESS_CMD = "light -G"
local path_to_icons = "/usr/share/icons/Arc/status/symbolic/"

local brightness_text = wibox.widget.textbox()
brightness_text:set_font('Play 9')

local brightness_icon = wibox.widget {
    {
    	image = path_to_icons .. "display-brightness-symbolic.svg",
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

watch(
    GET_BRIGHTNESS_CMD, 1,
    function(widget, stdout, stderr, exitreason, exitcode)
        local brightness_level = tonumber(string.format("%.0f", stdout))
        widget:set_text(" " .. brightness_level .. "%")
    end,
    brightness_text
)

return brightness_widget
