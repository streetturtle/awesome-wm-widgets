local wibox = require("wibox")
local awful = require("awful")
local watch = require("awful.widget.watch")

rhythmbox_widget = wibox.widget.textbox()
rhythmbox_widget:set_font('Play 9')

rhythmbox_icon = wibox.widget.imagebox()
rhythmbox_icon:set_image("/usr/share/icons/Arc/devices/22/audio-speakers.png")

watch(
    "rhythmbox-client --no-start --print-playing", 1,
    function(widget, stdout, stderr, exitreason, exitcode)
        rhythmbox_widget:set_text(stdout)
    end
)