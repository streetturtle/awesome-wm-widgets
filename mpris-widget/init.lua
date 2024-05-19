-------------------------------------------------
-- mpris based Arc Widget for Awesome Window Manager
-- Modelled after Pavel Makhov's work
-- @author Mohammed Gaber
-- requires - playerctl
-- @copyright 2020
-------------------------------------------------
local awful             = require("awful")
local beautiful         = require("beautiful")
local watch             = require("awful.widget.watch")
local wibox             = require("wibox")
local gears             = require("gears")

local GET_MPD_CMD       = "playerctl -f '{{status}};{{xesam:artist}};{{xesam:title}};{{mpris:artUrl}};{{position}};{{mpris:length}}' metadata"

local TOGGLE_MPD_CMD    = "playerctl play-pause"
local NEXT_MPD_CMD      = "playerctl next"
local PREV_MPD_CMD      = "playerctl previous"
local LIST_PLAYERS_CMD  = "playerctl -l"

local PATH_TO_ICONS     = "/usr/share/icons/Adwaita"
local PAUSE_ICON_NAME   = PATH_TO_ICONS .. "/symbolic/actions/media-playback-pause-symbolic.svg"
local PLAY_ICON_NAME    = PATH_TO_ICONS .. "/symbolic/actions/media-playback-start-symbolic.svg"
local STOP_ICON_NAME    = PATH_TO_ICONS .. "/symbolic/actions/media-playback-stop-symbolic.svg"
local LIBRARY_ICON_NAME = PATH_TO_ICONS .. "/symbolic/places/folder-music-symbolic.svg"

local FONT = 'Roboto Condensed 16px'

local default_player    = 'mpv'

local icon = wibox.widget {
    id = "icon",
    widget = wibox.widget.imagebox,
    image = PLAY_ICON_NAME
}

local progress_widget = wibox.widget {
    id = 'progress',
    widget = wibox.container.arcchart,
    icon,
    min_value = 0,
    max_value = 1,
    value = 0,
    thickness = 2,
    start_angle = 4.71238898, -- 2pi*3/4
    forced_height = 24,
    forced_width = 24,
    rounded_edge = true,
    bg = "#ffffff11",
    paddings = 2,
}

local artist_widget = wibox.widget {
    id = 'artist',
    font = FONT,
    widget = wibox.widget.textbox
}

local title_widget = wibox.widget {
    id = 'title',
    font = FONT,
    widget = wibox.widget.textbox
}

local mpris_widget = wibox.widget {
    artist_widget,
    progress_widget,
    title_widget,
    spacing = 4,
    layout = wibox.layout.fixed.horizontal,
}

local cover_art_widget = wibox.widget {
    widget = wibox.widget.imagebox,
    forced_height = 0,
    forced_width = 300,
    resize_allowed = true,
}

local metadata_widget = wibox.widget {
    widget        = wibox.widget.textbox,
    font          = FONT,
    forced_height = 100,
    forced_width  = 300,
}


local rows              = { layout = wibox.layout.fixed.vertical }

local popup             = awful.popup {
    bg = beautiful.bg_normal,
    fg = beautiful.fg_normal,
    ontop = true,
    visible = false,
    shape = gears.shape.rounded_rect,
    border_width = 1,
    border_color = beautiful.bg_focus,
    maximum_width = 400,
    offset = { y = 5 },
    widget = {}
}

local function rebuild_popup()
    awful.spawn.easy_async(LIST_PLAYERS_CMD, function(stdout, _, _, _)
        for i = 0, #rows do rows[i] = nil end
        for player_name in stdout:gmatch("[^\r\n]+") do
            if player_name ~= '' and player_name ~= nil then
                local checkbox = wibox.widget {
                    {
                        checked       = player_name == default_player,
                        color         = beautiful.bg_normal,
                        paddings      = 2,
                        shape         = gears.shape.circle,
                        forced_width  = 20,
                        forced_height = 20,
                        check_color   = beautiful.fg_normal,
                        widget        = wibox.widget.checkbox
                    },
                    valign = 'center',
                    layout = wibox.container.place,
                }

                checkbox:connect_signal("button::press", function()
                    default_player = player_name
                    rebuild_popup()
                end)

                table.insert(rows, wibox.widget {
                    {
                        {
                            checkbox,
                            {
                                {
                                    text = player_name,
                                    align = 'left',
                                    widget = wibox.widget.textbox
                                },
                                left = 10,
                                layout = wibox.container.margin
                            },
                            spacing = 8,
                            layout = wibox.layout.align.horizontal
                        },
                        margins = 4,
                        layout = wibox.container.margin
                    },
                    bg = beautiful.bg_normal,
                    fg = beautiful.fg_normal,
                    widget = wibox.container.background
                })
            end
        end
    end)

    popup:setup(rows)
end

local function update_metadata(artist, current_song, progress, art_url)
    artist_widget:set_text(artist)
    title_widget:set_text(current_song)
    progress_widget.value = progress

    -- poor man's urldecode
    art_url = art_url:gsub("file://", "/")
    art_url = art_url:gsub("%%(%x%x)", function(x) return string.char(tonumber(x, 16)) end)

    if art_url ~= nil and art_url ~= "" then
        cover_art_widget.image = art_url
        cover_art_widget.forced_height = 300
    else
        cover_art_widget.image = nil
        cover_art_widget.forced_height = 0
    end
end

local function worker()
    -- retrieve song info
    local current_song, artist, player_status, art_url, progress

    local update_graphic = function(widget, stdout, _, _, _)
        local words = gears.string.split(stdout, ';')
        player_status = words[1]
        artist = words[2]
        current_song = words[3]

        art_url = words[4]

        if current_song ~= nil then
            if string.len(current_song) > 40 then
                current_song = string.sub(current_song, 0, 38) .. "…"
            end
        end

        if player_status == "Playing" then
            icon.image = PLAY_ICON_NAME
            widget.colors = { beautiful.widget_main_color }
            if words[5] ~= nil and words[6] ~= nil then
                progress = tonumber(words[5]) / tonumber(words[6])
            end
            update_metadata(artist, current_song, progress, art_url)
        elseif player_status == "Paused" then
            icon.image = PAUSE_ICON_NAME
            widget.colors = { beautiful.widget_main_color }
            if words[5] ~= nil and words[6] ~= nil then
                progress = tonumber(words[5]) / tonumber(words[6])
            end
            update_metadata(artist, current_song, progress, art_url)
        elseif player_status == "Stopped" then
            icon.image = STOP_ICON_NAME
        else -- no player is running
            icon.image = LIBRARY_ICON_NAME
            widget.colors = { beautiful.widget_red }
        end
    end

    mpris_widget:buttons(
        awful.util.table.join(
            awful.button({}, 3, function()
                if popup.visible then
                    popup.visible = not popup.visible
                else
                    rebuild_popup()
                    popup:move_next_to(mouse.current_widget_geometry)
                end
            end),
            awful.button({}, 4, function() awful.spawn(NEXT_MPD_CMD, false) end),
            awful.button({}, 5, function() awful.spawn(PREV_MPD_CMD, false) end),
            awful.button({}, 1, function() awful.spawn(TOGGLE_MPD_CMD, false) end)
        )
    )

    watch(GET_MPD_CMD, 1, update_graphic, mpris_widget)

    local mpris_popup = awful.widget.watch(
        "playerctl metadata --format '{{ status }}: {{ artist }} - {{ title }}\n"
        .. "Duration: {{ duration(position) }}/{{ duration(mpris:length) }}'",
        1,
        function(callback_popup, stdout)
            local metadata = stdout
            if callback_popup.visible then
                metadata_widget:set_text(metadata)
                callback_popup:move_next_to(mouse.current_widget_geometry)
            end
        end,
        awful.popup {
            border_color = beautiful.border_color,
            ontop        = true,
            visible      = false,
            widget = wibox.widget {
                cover_art_widget,
                metadata_widget,
                layout = wibox.layout.fixed.vertical,
            }
        }
    )

    mpris_widget:connect_signal('mouse::enter',
        function()
            mpris_popup.visible = true
        end)
    mpris_widget:connect_signal('mouse::leave',
        function()
            mpris_popup.visible = false
        end)
    --}}

    return mpris_widget
end

return setmetatable(mpris_widget, { __call = function(_, ...) return worker(...) end })
