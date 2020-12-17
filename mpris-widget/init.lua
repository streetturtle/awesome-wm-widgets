-------------------------------------------------
-- mpris based Arc Widget for Awesome Window Manager
-- Modelled after Pavel Makhov's work
-- @author Mohammed Gaber
-- requires - playerctl
-- @copyright 2020
-------------------------------------------------
local awful = require("awful")
local beautiful = require("beautiful")
local spawn = require("awful.spawn")
local watch = require("awful.widget.watch")
local wibox = require("wibox")
local naughty = require("naughty")
local gears = require("gears")

local GET_MPD_CMD = "playerctl -p %s -f '{{status}};{{xesam:artist}};{{xesam:title}};{{mpris:artUrl}}' metadata"

local TOGGLE_MPD_CMD = "playerctl play-pause"
local PAUSE_MPD_CMD = "playerctl pause"
local STOP_MPD_CMD = "playerctl stop"
local NEXT_MPD_CMD = "playerctl next"
local PREV_MPD_CMD = "playerctl previous"
local LIST_PLAYERS_CMD = "playerctl -l"

local PATH_TO_ICONS = "/usr/share/icons/Arc"
local PAUSE_ICON_NAME = PATH_TO_ICONS .. "/actions/24/player_pause.png"
local PLAY_ICON_NAME = PATH_TO_ICONS .. "/actions/24/player_play.png"
local STOP_ICON_NAME = PATH_TO_ICONS .. "/actions/24/player_stop.png"
local LIBRARY_ICON_NAME = PATH_TO_ICONS .. "/actions/24/music-library.png"

local default_player = ''

local mpris_widget = wibox.widget{
    {
        id = 'artist',
        widget = wibox.widget.textbox
    },
    {
        max_value = 1,
        value = 0,
        thickness = 2,
        start_angle = 4.71238898, -- 2pi*3/4
        forced_height = 24,
        forced_width = 24,
        rounded_edge = true,
        bg = "#ffffff11",
        paddings = 0,
        widget = wibox.container.arcchart
    },
    {
        id = 'title',
        widget = wibox.widget.textbox
    },
    layout = wibox.layout.fixed.horizontal,
    set_text = function(self, artis, title)
        self:get_children_by_id('artist')[1]:set_text(artis)
        self:get_children_by_id('title')[1]:set_text(title)
    end
}

local rows  = { layout = wibox.layout.fixed.vertical }

local popup = awful.popup{
    bg = beautiful.bg_normal,
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
        for player_name in stdout:gmatch("[^\r\n]+") do
            if player_name ~='' or player_name ~=nil then
                for i = 0, #rows do rows[i]=nil end

                local checkbox = wibox.widget{
                    {
                        checked       = player_name == default_player,
                        color         = beautiful.bg_normal,
                        paddings      = 2,
                        shape         = gears.shape.circle,
                        forced_width = 20,
                        forced_height = 20,
                        check_color = beautiful.fg_urgent,
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
                    widget = wibox.container.background
                })
            end
        end
    end)

    popup:setup(rows)
end

local function worker()

    -- retriving song info
    local current_song, artist, mpdstatus, art, artUrl

    local icon = wibox.widget {
        id = "icon",
        widget = wibox.widget.imagebox,
        image = PLAY_ICON_NAME
    }
    local mirrored_icon = wibox.container.mirror(icon, {horizontal = true})

    local mpdarc = wibox.widget {
        mirrored_icon,
        -- max_value = 1,
        -- value = 0,
        thickness = 2,
        start_angle = 4.71238898, -- 2pi*3/4
        forced_height = 24,
        forced_width = 24,
        rounded_edge = true,
        bg = "#ffffff11",
        paddings = 0,
        widget = wibox.container.arcchart
    }

    local mpdarc_icon_widget = wibox.container.mirror(mpdarc, {horizontal = true})
    local mpdarc_current_song_widget = wibox.widget {
        id = 'current_song',
        widget = wibox.widget.textbox,
        font = 'Play 10'
    }

    local update_graphic = function(widget, stdout, _, _, _)
        -- mpdstatus, artist, current_song = stdout:match("(%w+)%;+(.-)%;(.*)")
        local words = {}
        for w in stdout:gmatch("([^;]*)") do table.insert(words, w) end

        mpdstatus = words[1]
        artist = words[2]
        current_song = words[3]
        art = words[4]
        if current_song ~= nil then
            if string.len(current_song) > 18 then
                current_song = string.sub(current_song, 0, 9) .. ".."
            end
        end

        if art ~= nil then artUrl = string.sub(art, 8, -1) end

        if mpdstatus == "Playing" then
            mpdarc_icon_widget.visible = true
            icon.image = PLAY_ICON_NAME
            widget.colors = {beautiful.widget_main_color}
            mpdarc_current_song_widget.markup = current_song
            widget:set_text(artist, current_song)
        elseif mpdstatus == "Paused" then
            mpdarc_icon_widget.visible = true
            icon.image = PAUSE_ICON_NAME
            widget.colors = {beautiful.widget_main_color}
            mpdarc_current_song_widget.markup = current_song
            widget.set_text(artist, current_song)
        elseif mpdstatus == "Stopped" then
            mpdarc_icon_widget.visible = true
            icon.image = STOP_ICON_NAME
            mpdarc_current_song_widget.markup = ""
        else -- no player is running
            icon.image = LIBRARY_ICON_NAME
            mpdarc_icon_widget.visible = false
            mpdarc_current_song_widget.markup = ""
            widget.colors = {beautiful.widget_red}
        end
    end

    mpdarc:connect_signal("button::press", function(_, _, _, button)
        if (button == 1) then
            awful.spawn(TOGGLE_MPD_CMD, false) -- left click
        elseif (button == 2) then
            awful.spawn(STOP_MPD_CMD, false)
        elseif (button == 3) then
            awful.spawn(PAUSE_MPD_CMD, false)
        elseif (button == 4) then
            awful.spawn(NEXT_MPD_CMD, false) -- scroll up
        elseif (button == 5) then
            awful.spawn(PREV_MPD_CMD, false) -- scroll down
        end

        -- spawn.easy_async(string.format(GET_MPD_CMD, "'" .. default_player .. "'"),
        -- function(stdout, stderr, exitreason, exitcode)
        --     update_graphic(mpdarc, stdout, stderr, exitreason, exitcode)
        -- end)
    end)

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



    local notification
    local function show_MPD_status()
        spawn.easy_async(GET_MPD_CMD, function()
            notification = naughty.notification {
                margin = 10,
                timeout = 5,
                hover_timeout = 0.5,
                width = 240,
                height = 90,
                title = "<b>" .. mpdstatus .. "</b>",
                text = current_song .. " <b>by</b> " .. artist,
                image = artUrl
            }
        end)
    end

    mpdarc:connect_signal("mouse::enter", function()
        if current_song ~= nil and artist ~= nil then show_MPD_status() end
    end)
    mpdarc:connect_signal("mouse::leave", function() naughty.destroy(notification) end)

    watch(string.format(GET_MPD_CMD, "'" .. default_player .. "'"), 1, update_graphic, mpris_widget)

    return mpris_widget

end

return setmetatable(mpris_widget, {__call = function(_, ...) return worker(...) end})
