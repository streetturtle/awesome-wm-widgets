-------------------------------------------------
-- Spotify Player Widget for Awesome Window Manager
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/spotify-player

-- @author Pavel Makhov
-- @copyright 2020 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local watch = require("awful.widget.watch")
local spawn = require("awful.spawn")
local naughty = require("naughty")
local gears = require("gears")
local beautiful = require("beautiful")
local gfs = require("gears.filesystem")
local gs = require("gears.string")

local HOME_DIR = os.getenv("HOME")

local spotify_player = {}

local BLUR_CMD = 'convert %s ( -clone 0 -fill white -colorize 100 -fill black -draw "polygon 0,200 300,200 300,300 0,300" -alpha off -write mpr:mask +delete ) -mask mpr:mask -blur 0x3 +mask %s'

local function show_warning(message)
    naughty.notify{
        preset = naughty.config.presets.critical,
        title = 'Bitbucket Widget',
        text = message}
end

local function worker(args)

    local args = args or {}

    local function get_artwork(track_id, url)
        if ((url ~= nil or url ~='') and not gfs.file_readable('/tmp/' .. track_id)) then
            spawn.easy_async('touch /tmp/' .. track_id, function()
                spawn.easy_async('curl -L -s --show-error --create-dirs -o /tmp/' .. track_id .. ' '.. url, function(stdout, stderr)
                    if stderr ~= '' then
                        show_warning(stderr)
                        return
                    end
                    -- spawn.easy_async(string.format(BLUR_CMD, '/tmp/' .. track_id, '/tmp/' .. track_id .. 'test'))
                end)
            end)
        end
    end

    local create_button = function (path)
        return wibox.widget {
            {   {
                   forced_width=32,
                   forced_height=32,
                   resize = true,
                   image = path,
                   widget = wibox.widget.imagebox
               },
               margins = 13,
               widget = wibox.container.margin,
           },
           forced_height = 50,
           forced_width = 50,
           shape              = function(cr, width, height)
               gears.shape.circle(cr, width, height, 20)
           end,
           shape_border_color = '#88888888',
           shape_border_width = 2,
           widget = wibox.container.background
       }
    end

    local popup = awful.popup{
        ontop = true,
        bg = beautiful.bg_normal .. '88',
        visible = false,
        shape = gears.shape.rounded_rect,
        border_width = 1,
        border_color = beautiful.bg_focus,
        maximum_width = 400,
        offset = { y = 5 },
        widget = {}
    }

    local rows = {
        expand = 'none',
        layout = wibox.layout.align.vertical,
    }

    spotify_player = wibox.widget {
        text = 'icon',
        widget = wibox.widget.textbox
    }

    local update_widget = function(widget, stdout, stderr, _, _)
        for i = 0, #rows do rows[i]=nil end

        local track_id, length, art_url, album, album_artist, artist, auto_rating, disc_number, title, track_number, url = 
            string.match(stdout, 'trackid|(.*)\nlength|(.*)\nartUrl|(.*)\nalbum|(.*)\nalbumArtist|(.*)\nartist|(.*)\nautoRating|(.*)\ndiscNumber|(.*)\ntitle|(.*)\ntrackNumber|(.*)\nurl|(.*)')

        title = string.gsub(title, "&", '&amp;')
        get_artwork(track_id, art_url)

        local artwork_widget = wibox.widget {
            -- image = '/tmp/' .. track_id .. 'test',
            image = '/tmp/' .. track_id,
            widget = wibox.widget.imagebox
        }

        local artist_w = wibox.widget {
            markup = '<span size="large" color="#ffffff">' .. artist .. '</span>',
            align = 'center',
            widget = wibox.widget.textbox
        }

        local title_w = wibox.widget {
            markup = '<span size="x-large" font_weight="bold" color="#ffffff">' .. title .. '</span>',
            align = 'center',
            forced_height = 30,
            widget = wibox.widget.textbox
        }

        local prev_button = create_button(HOME_DIR .. '/.config/awesome/awesome-wm-widgets/spotify-player/media-skip-backward-symbolic.svg')
        local play_button = create_button(HOME_DIR .. '/.config/awesome/awesome-wm-widgets/spotify-player/media-playback-start-symbolic.svg')
        local next_button = create_button(HOME_DIR .. '/.config/awesome/awesome-wm-widgets/spotify-player/media-skip-forward-symbolic.svg')

        -- prev_button:buttons(awful.util.table.join(awful.button({}, 1, function() prev_button:set_bg(beautiful.bg_focus);spawn.with_shell('sp prev') end)))
        play_button:buttons(awful.util.table.join(awful.button({}, 1, function() spawn.with_shell('sp play') end)))
        next_button:buttons(awful.util.table.join(awful.button({}, 1, function() spawn.with_shell('sp next') end)))

        prev_button:connect_signal("button::press", function(c) c:set_bg(beautiful.bg_focus) end)
        prev_button:connect_signal("button::release", function(c) c:set_bg(beautiful.bg_normal) spawn.with_shell('sp prev') end)

        local buttons_w = wibox.widget {
            {
                prev_button,
                play_button,
                next_button,
                spacing = 10,
                layout = wibox.layout.fixed.horizontal
            },
            halign = 'center',
            layout = wibox.container.place,
        }

        local some_w = wibox.widget {
            artwork_widget,
            {
                {
                    -- {
                        {
                            title_w,
                            artist_w,
                            buttons_w,
                            layout = wibox.layout.fixed.vertical
                        },
                        top = 10,
                        bottom = 10,
                        widget = wibox.container.margin
                    -- },
                    -- bg = '#33333388',
                    -- widget = wibox.container.background
                },
                valign = 'bottom',
                content_fill_horizontal = true,
                layout = wibox.container.place,
            },
            layout = wibox.layout.stack
        }

        popup:setup({
            -- artwork_widget,
            -- artist_w,
            -- title_w,
            some_w,
            -- buttons_w,
            layout = wibox.layout.fixed.vertical,
        })
    end

    spotify_player:buttons(
            awful.util.table.join(
                    awful.button({}, 1, function()
                        if popup.visible then
                            popup.visible = not popup.visible
                        else
                            popup:move_next_to(mouse.current_widget_geometry)
                        end
                    end)
            )
    )

    watch('sp metadata', 1, update_widget, spotify_player)

    return spotify_player
end

return setmetatable(spotify_player, { __call = function(_, ...) return worker(...) end })
