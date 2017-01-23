local wibox = require("wibox")
local awful = require("awful")

spotify_widget = wibox.widget.textbox()
spotify_widget:set_font('Play 9')

function updateSpotifyWidget(widget)
    awful.spawn.easy_async([[bash -c 'sp current-oneline']],
    function(stdout, stderr, reason, exit_code)
        widget:set_text(stdout)
    end)
end

spotify_timer = timer ({timeout = 10})
spotify_timer:connect_signal ("timeout", function() updateSpotifyWidget(spotify_widget) end) 
spotify_timer:start()

spotify_timer:emit_signal("timeout")
