local wibox = require("wibox")
local awful = require("awful")
local watch = require("awful.widget.watch")

local get_spotify_status_cmd = '/home/'.. os.getenv("USER") .. '/.config/awesome/awesome-wm-widgets/spotify-widget/spotify_stat'
local get_current_song_cmd = 'sp current-oneline'

spotify_widget = wibox.widget {
    {
        id = "icon",
        widget = wibox.widget.imagebox,
    },
    {
        id = 'current_song',
        widget = wibox.widget.textbox,
        font = 'Play 9'
    },
    layout  = wibox.layout.align.horizontal,
    set_image = function(self, path)
        self.icon.image = path
    end,
    set_text = function(self, path)
        self.current_song.text = path
    end,
}

local update_widget_icon = function(widget, stdout, _, _, _)
    stdout = string.gsub(stdout, "\n", "")
    if (stdout == 'RUNNING') then
        widget:set_image("/usr/share/icons/Arc/actions/24/player_play.png")
    elseif (stdout == "CORKED") then
        widget:set_image("/usr/share/icons/Arc/actions/24/player_pause.png")
    else
        widget:set_image(nil)
    end
end

local update_widget_text = function(widget, stdout, _, _, _)
    if string.find(stdout, 'Error: Spotify is not running.') ~= nil then
        widget:set_text('')
        widget:set_visible(false)
    else
        widget:set_text(stdout)
        widget:set_visible(true)
    end
end

watch(get_spotify_status_cmd, 1, update_widget_icon, spotify_widget)
watch(get_current_song_cmd, 1, update_widget_text, spotify_widget)

--[[
-- Adds mouse control to the widget:
--  - left click - play/pause
--  - scroll up - play next song
--  - scroll down - play previous song ]]
spotify_widget:connect_signal("button::press", function(_, _, _, button)
    if (button == 1) then awful.spawn("sp play", false)      -- left click
    elseif (button == 4) then awful.spawn("sp next", false)  -- scroll up
    elseif (button == 5) then awful.spawn("sp prev", false)  -- scroll down
    end
    awful.spawn.easy_async(get_spotify_status_cmd, function(stdout, stderr, exitreason, exitcode)
        update_widget_icon(spotify_widget, stdout, stderr, exitreason, exitcode)
    end)
end)