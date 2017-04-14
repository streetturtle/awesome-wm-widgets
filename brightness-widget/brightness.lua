local wibox = require("wibox")
local awful = require("awful")
local gears = require("gears")
local watch = require("awful.widget.watch")

brightness_widget = wibox.widget.textbox()
brightness_widget:set_font('Play 9')

brightness_icon = wibox.widget {
    {
    	image = "/usr/share/icons/Arc/status/symbolic/display-brightness-symbolic.svg",
    	resize = false,
        widget = wibox.widget.imagebox,
    },
    layout = wibox.container.margin(brightness_icon, 0, 0, 3)
}

watch(
    "xbacklight -get", 1,
    function(widget, stdout, stderr, exitreason, exitcode)
        local brightness_level = tonumber(string.format("%.0f", stdout))
        widget:set_text(brightness_level)
    end,
    brightness_widget
)