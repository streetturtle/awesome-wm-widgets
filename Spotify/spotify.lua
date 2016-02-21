local wibox = require("wibox")
local awful = require("awful")

spotify_widget = wibox.widget.textbox()

function updateSpotifyWidget(widget)
  local current = awful.util.pread('sp current-oneline')
  widget:set_text(current)
end

spotify_timer = timer ({timeout = 10})
spotify_timer:connect_signal ("timeout", function() updateSpotifyWidget(spotify_widget) end) 
spotify_timer:start()

spotify_timer:emit_signal("timeout")