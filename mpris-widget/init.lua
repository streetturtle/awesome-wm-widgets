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

local PATH_TO_ICONS     = "/usr/share/icons/Adwaita"
local PAUSE_ICON_NAME   = PATH_TO_ICONS .. "/symbolic/actions/media-playback-pause-symbolic.svg"
local PLAY_ICON_NAME    = PATH_TO_ICONS .. "/symbolic/actions/media-playback-start-symbolic.svg"
local STOP_ICON_NAME    = PATH_TO_ICONS .. "/symbolic/actions/media-playback-stop-symbolic.svg"
local LIBRARY_ICON_NAME = PATH_TO_ICONS .. "/symbolic/places/folder-music-symbolic.svg"

local FONT = 'Roboto Condensed 16px'

local playerctl = {
    player_name = 'mpv',
}

function playerctl:set_player(name)
    self.player_name = name

    if self.timer ~= nil then
        self.timer:stop()
        playerctl:watch(self.watch_params.timeout, self.watch_params.callback, self.watch_params.widget)
    end
end

function playerctl:cmd(cmd)
    return "playerctl -p '" .. self.player_name .. "' " .. cmd
end

function playerctl:watch(timeout, callback, widget)
    local cmd = self:cmd("-f '{{status}};{{xesam:artist}};{{xesam:title}};{{mpris:artUrl}};{{position}};{{mpris:length}};{{album}}' metadata")

    self.watch_params = {timeout = timeout, callback = callback, widget = widget}

    local cb = function(widget, stdout, _, _, _)
        local words = gears.string.split(stdout, ';')

        local progress
        if words[5] ~= nil and words[6] ~= nil then
            progress = tonumber(words[5]) / tonumber(words[6])
        end

        local metadata = {
            status = words[1],
            artist = words[2],
            current_song = words[3],
            art_url = words[4],
            position = words[5],
            length = words[6],
            album = words[7],
            progress = progress,
        }

        callback(widget, metadata)
    end

    _, self.timer = awful.widget.watch(cmd, timeout, cb, widget)
end

function playerctl:toggle()
    awful.spawn(self:cmd("play-pause"), false)
end

function playerctl:next()
    awful.spawn(self:cmd("next"), false)
end

function playerctl:prev()
    awful.spawn(self:cmd("previous"), false)
end

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

local player_selector_popup = {
    popup             = awful.popup {
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
    },

    rows              = { layout = wibox.layout.fixed.vertical },
}

function player_selector_popup:add_radio_button(player_name)
    local checkbox = wibox.widget {
        {
            checked       = player_name == playerctl.player_name,
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
        playerctl:set_player(player_name)
        self:toggle()
    end)

    table.insert(self.rows, wibox.widget {
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

function player_selector_popup:rebuild()
    self.rows              = { layout = wibox.layout.fixed.vertical }
    awful.spawn.easy_async("playerctl -l", function(stdout, _, _, _)
        for name in stdout:gmatch("[^\r\n]+") do
            if name ~= '' and name ~= nil then
                self:add_radio_button(name)
            end
        end

        self.popup:setup(self.rows)
        self.popup.visible = true
        self.popup:move_next_to(mouse.current_widget_geometry)
    end)
end

function player_selector_popup:toggle()
    if self.popup.visible then
        self.popup.visible = false
    else
        self:rebuild()
    end
end

local function duration(microseconds)
    local seconds = microseconds / 1000000
    local minutes = seconds / 60
    seconds = seconds % 60
    local hours = minutes / 60
    minutes = minutes % 60
    if hours >= 1 then
        return string.format("%.f:%02.f:%02.f", hours, minutes, seconds)
    end
    return string.format("%.f:%02.f", minutes, seconds)
end

local function worker()
    local update_metadata = function(meta)
        artist_widget:set_text(meta.artist)
        title_widget:set_text(meta.current_song)
        metadata_widget:set_text(string.format('%s - %s (%s/%s)', meta.album, meta.current_song, duration(meta.position), duration(meta.length)))
        progress_widget.value = meta.progress

        -- poor man's urldecode
        local art_url = meta.art_url:gsub("file://", "/")
        art_url = art_url:gsub("%%(%x%x)", function(x) return string.char(tonumber(x, 16)) end)

        if art_url ~= nil and art_url ~= "" then
            cover_art_widget.image = art_url
            cover_art_widget.forced_height = 300
        else
            cover_art_widget.image = nil
            cover_art_widget.forced_height = 0
        end
    end

    local update_graphic = function(widget, metadata)
        if metadata.current_song ~= nil then
            if string.len(metadata.current_song) > 40 then
                metadata.current_song = string.sub(metadata.current_song, 0, 38) .. "…"
            end
        end

        if metadata.status == "Playing" then
            icon.image = PLAY_ICON_NAME
            widget.colors = { beautiful.widget_main_color }
            update_metadata(metadata)
        elseif metadata.status == "Paused" then
            icon.image = PAUSE_ICON_NAME
            widget.colors = { beautiful.widget_main_color }
            update_metadata(metadata)
        elseif metadata.status == "Stopped" then
            icon.image = STOP_ICON_NAME
        else -- no player is running
            icon.image = LIBRARY_ICON_NAME
            widget.colors = { beautiful.widget_red }
        end
    end

    mpris_widget:buttons(
        awful.util.table.join(
            awful.button({}, 3, function() player_selector_popup:toggle() end),
            awful.button({}, 4, function() playerctl:next() end),
            awful.button({}, 5, function() playerctl:prev() end),
            awful.button({}, 1, function() playerctl:toggle() end)
        )
    )

    playerctl:watch(1, update_graphic, mpris_widget)

    local mpris_popup = awful.popup {
        border_color = beautiful.border_color,
        ontop        = true,
        visible      = false,
        widget = wibox.widget {
            cover_art_widget,
            metadata_widget,
            layout = wibox.layout.fixed.vertical,
        }
    }

    mpris_widget:connect_signal('mouse::enter',
        function()
            mpris_popup.visible = true
            mpris_popup:move_next_to(mouse.current_widget_geometry)
        end)
    mpris_widget:connect_signal('mouse::leave',
        function()
            mpris_popup.visible = false
        end)
    --}}

    return mpris_widget
end

return setmetatable(mpris_widget, { __call = function(_, ...) return worker(...) end })
