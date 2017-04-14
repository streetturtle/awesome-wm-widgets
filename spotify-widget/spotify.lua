local wibox = require("wibox")
local awful = require("awful")
local watch = require("awful.widget.watch")

spotify_widget = wibox.widget.textbox()
spotify_widget:set_font('Play 9')
spotify_widget:connect_signal("button::release", function() awful.spawn('sp play'); end)

-- optional icon, could be replaced by spotfiy logo (https://developer.spotify.com/design/)
spotify_icon = wibox.widget.imagebox()
spotify_icon:set_image("/usr/share/icons/Arc/devices/22/audio-headphones.png")

watch(
    "sp current-oneline", 1,
    function(widget, stdout, stderr, exitreason, exitcode)
        spotify_widget:set_text(stdout)
    end
)
