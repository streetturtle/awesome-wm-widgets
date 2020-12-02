-------------------------------------------------
-- Spotify Widget for Awesome Window Manager
-- Shows currently playing song on Spotify for Linux client
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/spotify-widget

-- @author Pavel Makhov
-- @copyright 2020 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local watch = require("awful.widget.watch")

local GET_SPOTIFY_STATUS_CMD = 'sp status'
local GET_CURRENT_SONG_CMD = 'sp current'

local function ellipsize(text, length)
    return (text:len() > length and length > 0)
        and text:sub(0, length - 3) .. '...'
        or text
end

local spotify_widget = {}

local function worker(user_args)

    local args = user_args or {}

    local play_icon = args.play_icon or '/usr/share/icons/Arc/actions/24/player_play.png'
    local pause_icon = args.pause_icon or '/usr/share/icons/Arc/actions/24/player_pause.png'
    local font = args.font or 'Play 9'
    local dim_when_paused = args.dim_when_paused == nil and false or args.dim_when_paused
    local dim_opacity = args.dim_opacity or 0.2
    local max_length = args.max_length or 15
    local show_tooltip = args.show_tooltip == nil and true or args.show_tooltip
    local timeout = args.timeout or 1

    local cur_artist = ''
    local cur_title = ''
    local cur_album = ''

    spotify_widget = wibox.widget {
        {
            id = 'artistw',
            font = font,
            widget = wibox.widget.textbox,
        },
        {
            id = "icon",
            widget = wibox.widget.imagebox,
        },
        {
            layout = wibox.container.scroll.horizontal,
            max_size = 100,
            step_function = wibox.container.scroll.step_functions.waiting_nonlinear_back_and_forth,
            speed = 40,
            {
                id = 'titlew',
                font = font,
                widget = wibox.widget.textbox
            }
        },
        layout = wibox.layout.align.horizontal,
        set_status = function(self, is_playing)
            self.icon.image = (is_playing and play_icon or pause_icon)
            if dim_when_paused then
                self:get_children_by_id('icon')[1]:set_opacity(is_playing and 1 or dim_opacity)

                self:get_children_by_id('titlew')[1]:set_opacity(is_playing and 1 or dim_opacity)
                self:get_children_by_id('titlew')[1]:emit_signal('widget::redraw_needed')

                self:get_children_by_id('artistw')[1]:set_opacity(is_playing and 1 or dim_opacity)
                self:get_children_by_id('artistw')[1]:emit_signal('widget::redraw_needed')
            end
        end,
        set_text = function(self, artist, song)
            local artist_to_display = ellipsize(artist, max_length)
            if self:get_children_by_id('artistw')[1]:get_markup() ~= artist_to_display then
                self:get_children_by_id('artistw')[1]:set_markup(artist_to_display)
            end
            local title_to_display = ellipsize(song, max_length)
            if self:get_children_by_id('titlew')[1]:get_markup() ~= title_to_display then
                self:get_children_by_id('titlew')[1]:set_markup(title_to_display)
            end
        end
    }

    local update_widget_icon = function(widget, stdout, _, _, _)
        stdout = string.gsub(stdout, "\n", "")
        widget:set_status(stdout == 'Playing' and true or false)
    end

    local update_widget_text = function(widget, stdout, _, _, _)
        if string.find(stdout, 'Error: Spotify is not running.') ~= nil then
            widget:set_text('','')
            widget:set_visible(false)
            return
        end

        local escaped = string.gsub(stdout, "&", '&amp;')
        local album, _, artist, title =
            string.match(escaped, 'Album%s*(.*)\nAlbumArtist%s*(.*)\nArtist%s*(.*)\nTitle%s*(.*)\n')

        if album ~= nil and title ~=nil and artist ~= nil then
            cur_artist = artist
            cur_title = title
            cur_album = album

            widget:set_text(artist, title)
            widget:set_visible(true)
        end
    end

    watch(GET_SPOTIFY_STATUS_CMD, timeout, update_widget_icon, spotify_widget)
    watch(GET_CURRENT_SONG_CMD, timeout, update_widget_text, spotify_widget)

    --- Adds mouse controls to the widget:
    --  - left click - play/pause
    --  - scroll up - play next song
    --  - scroll down - play previous song
    spotify_widget:connect_signal("button::press", function(_, _, _, button)
        if (button == 1) then
            awful.spawn("sp play", false)      -- left click
        elseif (button == 4) then
            awful.spawn("sp next", false)  -- scroll up
        elseif (button == 5) then
            awful.spawn("sp prev", false)  -- scroll down
        end
        awful.spawn.easy_async(GET_SPOTIFY_STATUS_CMD, function(stdout, stderr, exitreason, exitcode)
            update_widget_icon(spotify_widget, stdout, stderr, exitreason, exitcode)
        end)
    end)


    if show_tooltip then
        local spotify_tooltip = awful.tooltip {
            mode = 'outside',
            preferred_positions = {'bottom'},
         }

        spotify_tooltip:add_to_object(spotify_widget)

        spotify_widget:connect_signal('mouse::enter', function()
            spotify_tooltip.markup = '<b>Album</b>: ' .. cur_album
                .. '\n<b>Artist</b>: ' .. cur_artist
                .. '\n<b>Song</b>: ' .. cur_title
        end)
    end

    return spotify_widget

end

return setmetatable(spotify_widget, { __call = function(_, ...)
    return worker(...)
end })