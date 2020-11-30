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

local GET_MPD_CMD =
    "playerctl -f '{{status}};{{xesam:artist}};{{xesam:title}};{{mpris:artUrl}}' metadata"

local TOGGLE_MPD_CMD = "playerctl play-pause"
local PAUSE_MPD_CMD = "playerctl pause"
local STOP_MPD_CMD = "playerctl stop"
local NEXT_MPD_CMD = "playerctl next"
local PREV_MPD_CMD = "playerctl previous"

local PATH_TO_ICONS = "/usr/share/icons/Arc"
local PAUSE_ICON_NAME = PATH_TO_ICONS .. "/actions/24/player_pause.png"
local PLAY_ICON_NAME = PATH_TO_ICONS .. "/actions/24/player_play.png"
local STOP_ICON_NAME = PATH_TO_ICONS .. "/actions/24/player_stop.png"
local LIBRARY_ICON_NAME = PATH_TO_ICONS .. "/actions/24/music-library.png"

local mpdarc_widget = {}

local function worker(args)

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

    local mpdarc_icon_widget = wibox.container.mirror(mpdarc,
                                                      {horizontal = true})
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
        elseif mpdstatus == "Paused" then
            mpdarc_icon_widget.visible = true
            icon.image = PAUSE_ICON_NAME
            widget.colors = {beautiful.widget_main_color}
            mpdarc_current_song_widget.markup = current_song
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

        spawn.easy_async(GET_MPD_CMD,
                         function(stdout, stderr, exitreason, exitcode)
            update_graphic(mpdarc, stdout, stderr, exitreason, exitcode)
        end)
    end)

    local notification
    local function show_MPD_status()
        spawn.easy_async(GET_MPD_CMD, function(stdout, _, _, _)
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
    mpdarc:connect_signal("mouse::leave",
                          function() naughty.destroy(notification) end)

    watch(GET_MPD_CMD, 1, update_graphic, mpdarc)

    mpdarc_widget = wibox.widget {
        screen = 'primary',
        mpdarc_icon_widget,
        mpdarc_current_song_widget,
        layout = wibox.layout.align.horizontal
    }
    return mpdarc_widget

end

return setmetatable(mpdarc_widget,
                    {__call = function(_, ...) return worker(...) end})
