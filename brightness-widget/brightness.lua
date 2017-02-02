local wibox = require("wibox")
local awful = require("awful")
local watch = require("awful.widget.watch")

brightness_widget = wibox.widget.textbox()
brightness_widget:set_font('Play 9')

brightness_icon = wibox.widget.imagebox()
brightness_icon:set_image("/usr/share/icons/Arc/actions/22/object-inverse.png")

watch(
    "xbacklight -get", 1,
    function(widget, stdout, stderr, exitreason, exitcode)
        local brightness_level = tonumber(string.format("%.0f", stdout))
        brightness_widget:set_text(brightness_level)
    end
)