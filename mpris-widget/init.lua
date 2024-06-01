-------------------------------------------------
-- mpris based Arc Widget for Awesome Window Manager
-- Modelled after Pavel Makhov's work
-- @author Mohammed Gaber
-- requires - playerctl
-- @copyright 2020
-------------------------------------------------
local awful = require('awful')
local beautiful = require('beautiful')
local watch = require('awful.widget.watch')
local wibox = require('wibox')
local gears = require('gears')

local playerctl = {
    player_name = nil,
}

function playerctl:set_player(name)
    self.player_name = name

    if self.timer ~= nil then
        self.timer:stop()
        playerctl:watch(self.watch_params.timeout, self.watch_params.callback, self.watch_params.widget)
    end
end

function playerctl:cmd(cmd) return "playerctl -p '" .. self.player_name .. "' " .. cmd end

local watch_fields = {
    [1] = 'status',
    [2] = 'xesam:artist',
    [3] = 'xesam:title',
    [4] = 'mpris:artUrl',
    [5] = 'position',
    [6] = 'mpris:length',
    [7] = 'album',
    [8] = 'xesam:contentCreated',
}

local watch_cmd = string.format("-f '{{%s}}' metadata", table.concat(watch_fields, '}};{{'))

function playerctl:watch(timeout, callback, widget)
    local cmd = self:cmd(watch_cmd)

    self.watch_params = { timeout = timeout, callback = callback, widget = widget }

    local cb = function(widget, stdout, _, _, _)
        local words = gears.string.split(stdout, ';')

        local position, length, progress = tonumber(words[5]), tonumber(words[6])

        if position ~= nil and length ~= nil and length > 0 then
            progress = position / length
        end

        local metadata = {
            status = words[1],
            artist = words[2],
            current_song = words[3],
            art_url = words[4],
            position = position,
            length = length,
            album = words[7],
            progress = progress,
        }

        if words[8] ~= nil then
            metadata.year = string.sub(words[8], 0, 4)
        end

        callback(widget, metadata)
    end

    _, self.timer = awful.widget.watch(cmd, timeout, cb, widget)
end

function playerctl:toggle() awful.spawn(self:cmd('play-pause'), false) end

function playerctl:next() awful.spawn(self:cmd('next'), false) end

function playerctl:prev() awful.spawn(self:cmd('previous'), false) end

local player_selector_popup = {
    popup = awful.popup {
        bg = beautiful.bg_normal,
        fg = beautiful.fg_normal,
        ontop = true,
        visible = false,
        shape = gears.shape.rounded_rect,
        border_width = 1,
        border_color = beautiful.bg_focus,
        maximum_width = 400,
        offset = { y = 5 },
        widget = {},
    },

    rows = { layout = wibox.layout.fixed.vertical },
}

function player_selector_popup:add_radio_button(player_name)
    local checkbox = wibox.widget {
        layout = wibox.container.place,
        valign = 'center',
        {
            checked = player_name == playerctl.player_name,
            color = beautiful.bg_normal,
            paddings = 2,
            shape = gears.shape.circle,
            forced_width = 20,
            forced_height = 20,
            check_color = beautiful.fg_normal,
            widget = wibox.widget.checkbox,
        },
    }

    checkbox:connect_signal('button::press', function()
        playerctl:set_player(player_name)
        self:toggle()
    end)

    local row = wibox.widget {
        {
            {
                checkbox,
                {
                    {
                        text = player_name,
                        align = 'left',
                        widget = wibox.widget.textbox,
                    },
                    left = 10,
                    layout = wibox.container.margin,
                },
                spacing = 8,
                layout = wibox.layout.align.horizontal,
            },
            margins = 4,
            layout = wibox.container.margin,
        },
        bg = beautiful.bg_normal,
        fg = beautiful.fg_normal,
        widget = wibox.container.background,
    }

    table.insert(self.rows, row)
end

function player_selector_popup:rebuild()
    awful.spawn.easy_async('playerctl -l', function(stdout, _, _, _)
        for i = 0, #self.rows do
            self.rows[i] = nil
        end

        for name in stdout:gmatch('[^\r\n]+') do
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
    if microseconds == nil then
        return '--:--'
    end

    local seconds = math.floor(microseconds / 1000000)
    local minutes = math.floor(seconds / 60)
    seconds = seconds - minutes * 60
    local hours = math.floor(minutes / 60)
    minutes = minutes - hours * 60
    if hours >= 1 then
        return string.format('%d:%02d:%02d', hours, minutes, seconds)
    end
    return string.format('%d:%02d', minutes, seconds)
end

local mpris_widget = {}

local function worker(user_args)
    local args = user_args or {}

    local font = args.font or 'Roboto Condensed 16px'

    local path_to_icons = '/usr/share/icons/Adwaita'

    local pause_icon = args.pause_icon or path_to_icons .. '/symbolic/actions/media-playback-pause-symbolic.svg'
    local play_icon = args.play_icon or path_to_icons .. '/symbolic/actions/media-playback-start-symbolic.svg'
    local stop_icon = args.stop_icon or path_to_icons .. '/symbolic/actions/media-playback-stop-symbolic.svg'
    local library_icon = args.library_icon or path_to_icons .. '/symbolic/places/folder-music-symbolic.svg'
    local popup_width = args.popup_width or 300

    playerctl.player_name = args.default_player or 'mpv'

    local icon = wibox.widget {
        widget = wibox.widget.imagebox,
        image = play_icon,
    }

    local progress_widget = wibox.widget {
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
        colors = { '#ffffff11', 'black' },
        paddings = 2,
    }

    local artist_widget = wibox.widget {
        font = font,
        widget = wibox.widget.textbox,
    }

    local title_widget = wibox.widget {
        font = font,
        widget = wibox.widget.textbox,
    }

    mpris_widget = wibox.widget {
        artist_widget,
        progress_widget,
        title_widget,
        spacing = 4,
        layout = wibox.layout.fixed.horizontal,
    }

    local cover_art_widget = wibox.widget {
        widget = wibox.widget.imagebox,
        forced_height = 0,
        forced_width = popup_width,
        resize_allowed = true,
    }

    local metadata_widget = wibox.widget {
        widget = wibox.widget.textbox,
        font = font,
        forced_height = 100,
        forced_width = popup_width,
    }

    local update_metadata = function(meta)
        artist_widget:set_text(meta.artist)
        title_widget:set_text(meta.current_song)

        local s = meta.album
        if meta.year ~= nil and #meta.year == 4 then
            s = s .. ' (' .. meta.year .. ')'
        end
        s = s .. '\n' .. meta.current_song .. ' (' .. duration(meta.position) .. '/' .. duration(meta.length) .. ')'
        metadata_widget:set_text(s)

        progress_widget.values = { 1.0 - (meta.progress or 0.0), meta.progress or 0.0 }

        -- poor man's urldecode
        local art_url = meta.art_url:gsub('file://', '/')
        art_url = art_url:gsub('%%(%x%x)', function(x) return string.char(tonumber(x, 16)) end)

        if art_url ~= nil and art_url ~= '' then
            cover_art_widget.image = art_url
            cover_art_widget.forced_height = popup_width
        else
            cover_art_widget.image = nil
            cover_art_widget.forced_height = 0
        end
    end

    local update_graphic = function(widget, metadata)
        if metadata.current_song ~= nil then
            if string.len(metadata.current_song) > 40 then
                metadata.current_song = string.sub(metadata.current_song, 0, 38) .. '…'
            end
        end

        if metadata.status == 'Playing' then
            icon.image = pause_icon
            widget.colors = { beautiful.widget_main_color }
            update_metadata(metadata)
        elseif metadata.status == 'Paused' then
            icon.image = play_icon
            widget.colors = { beautiful.widget_main_color }
            update_metadata(metadata)
        elseif metadata.status == 'Stopped' then
            icon.image = stop_icon
        else -- no player is running
            icon.image = library_icon
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
        ontop = true,
        visible = false,
        widget = wibox.widget {
            cover_art_widget,
            metadata_widget,
            layout = wibox.layout.fixed.vertical,
        },
    }

    mpris_widget:connect_signal('mouse::enter', function()
        mpris_popup.visible = true
        mpris_popup:move_next_to(mouse.current_widget_geometry)
    end)
    mpris_widget:connect_signal('mouse::leave', function() mpris_popup.visible = false end)
    --}}

    return mpris_widget
end

return setmetatable(mpris_widget, {
    __call = function(_, ...) return worker(...) end,
})
