-------------------------------------------------
-- Spotify Player Widget for Awesome Window Manager
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/spotify-player

-- @author Pavel Makhov
-- @copyright 2021 Pavel Makhov
-------------------------------------------------
--luacheck:ignore
local awful = require("awful")
local wibox = require("wibox")
local watch = require("awful.widget.watch")
local spawn = require("awful.spawn")
local naughty = require("naughty")
local gears = require("gears")
local beautiful = require("beautiful")
local gfs = require("gears.filesystem")
local gs = require("gears.string")
local awesomebuttons = require("awesome-buttons.awesome-buttons")

local HOME_DIR = os.getenv("HOME")
local WIDGET_DIR = HOME_DIR .. '/.config/awesome/awesome-wm-widgets/experiments/spotify-player/'
local ICON_DIR = WIDGET_DIR

local spotify_player = {}

local function show_warning(message)
    naughty.notify{
        preset = naughty.config.presets.critical,
        title = 'Spotify Player Widget',
        text = message}
end

local function worker(user_args)

    local args = user_args or {}
    local artwork_size = args.artwork_size or 300

    local timeout = args.timeout or 1

    local popup = awful.popup{
        ontop = true,
        bg = beautiful.bg_normal .. '88',
        visible = false,
        shape = gears.shape.rounded_rect,
        border_width = 1,
        border_color = beautiful.bg_focus,
        width = artwork_size,
        maximum_width = 300,
        offset = { y = 5 },
        widget = {}
    }

    local rows = {
        expand = 'none',
        layout = wibox.layout.align.vertical,
    }

    spotify_player.widget = wibox.widget {
        image = ICON_DIR .. 'spotify-indicator.svg',
        widget = wibox.widget.imagebox
    }

    local artwork_widget = wibox.widget {
        forced_height = artwork_size,
        forced_width = artwork_size,
        widget = wibox.widget.imagebox
    }

    local artist_w = wibox.widget {
        align = 'center',
        widget = wibox.widget.textbox,
        set_artist = function(self, artist)
            self:set_markup('<span size="large" color="#ffffff">' .. artist .. '</span>')
        end
    }

    local title_w = wibox.widget {
        align = 'center',
        forced_height = 30,
        widget = wibox.widget.textbox,
        set_title = function(self, title)
            self:set_markup('<span size="x-large" font_weight="bold" color="#ffffff">' .. title .. '</span>')
        end
    }

    local play_pause_btn = awesomebuttons.with_icon{ type = 'outline', icon = 'play', icon_size = 32, icon_margin = 8, color = '#1DB954', shape = 'circle', onclick = function()
        spawn.with_shell('sp play')
    end}

    local buttons_w = wibox.widget {
        {
            awesomebuttons.with_icon{ icon = 'rewind', icon_size = 32, icon_margin = 8, color = '#18800000', shape = 'circle', onclick = function()
                spawn.with_shell('sp prev')
            end},
            play_pause_btn,
            awesomebuttons.with_icon{ icon = 'fast-forward', icon_size = 32, icon_margin = 8, color = '#18800000', shape = 'circle', onclick = function()
                spawn.with_shell('sp next')
            end},
            spacing = 16,
            layout = wibox.layout.fixed.horizontal
        },
        halign = 'center',
        layout = wibox.container.place,
    }

    local some_w = wibox.widget {
        artwork_widget,
        {
            {
                {
                    {
                        title_w,
                        artist_w,
                        buttons_w,
                        layout = wibox.layout.fixed.vertical
                    },
                    top = 8,
                    bottom = 8,
                    widget = wibox.container.margin
                },
                bg = '#33333388',
                widget = wibox.container.background
            },
            valign = 'bottom',
            content_fill_horizontal = true,
            layout = wibox.container.place,
        },
        layout = wibox.layout.stack
    }

    popup:setup({
        some_w,
        layout = wibox.layout.fixed.vertical,
    })

    local update_widget = function(widget, stdout, stderr, _, _)
        for i = 0, #rows do rows[i]=nil end

        if string.find(stdout, 'Error: Spotify is not running.') ~= nil then
            return
        end

        local track_id, length, art_url, album, album_artist, artist, auto_rating, disc_number, title, track_number, url =
            string.match(stdout, 'trackid|(.*)\nlength|(.*)\nartUrl|(.*)\nalbum|(.*)\nalbumArtist|(.*)\nartist|(.*)\nautoRating|(.*)\ndiscNumber|(.*)\ntitle|(.*)\ntrackNumber|(.*)\nurl|(.*)')

        title = string.gsub(title, "&", '&amp;')
        artist_w:set_artist(artist)
        title_w:set_title(title)

        -- spotify client bug: https://community.spotify.com/t5/Desktop-Linux/MPRIS-cover-art-url-file-not-found/td-p/4920104
        art_url = art_url:gsub('https://open.spotify.com', 'https://i.scdn.co')
        if ((art_url ~= nil or art_url ~='') and not gfs.file_readable('/tmp/' .. track_id)) then
            spawn.easy_async('touch /tmp/' .. track_id, function()
                spawn.easy_async('curl -L -s --show-error --create-dirs -o /tmp/' .. track_id .. ' '.. art_url, function(stdout, stderr)
                    if stderr ~= '' then
                        show_warning(stderr)
                        return
                    end
                    artwork_widget:set_image('/tmp/' .. track_id)
                end)
            end)
        else
            artwork_widget:set_image('/tmp/' .. track_id)
        end
    end

    function spotify_player:tog()
        if popup.visible then
            popup.visible = not popup.visible
        else
            popup:move_next_to(mouse.current_widget_geometry)
        end
    end

    spotify_player.widget:buttons(
            awful.util.table.join(
                    awful.button({}, 1, function() spotify_player:tog() end)
            )
    )

    watch('sp metadata', timeout, update_widget)

    watch('sp status', 1, function(_, stdout)
        stdout = string.gsub(stdout, "\n", "")
        play_pause_btn:set_icon(stdout == 'Playing' and 'pause' or 'play')
    end)

    return spotify_player
end

return setmetatable(spotify_player, { __call = function(_, ...) return worker(...) end })
