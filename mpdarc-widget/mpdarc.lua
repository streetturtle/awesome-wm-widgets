-------------------------------------------------
-- mpd Arc Widget for Awesome Window Manager
--
-- Modelled after Pavel Makhov's work
-- See his github repo: https://github.com/streetturtle/awesome-wm-widgets/

-- @author Raphaël Fournier-S'niehotta
-- @copyright 2018 Raphaël Fournier-S'niehotta
-------------------------------------------------

local awful = require("awful")
local beautiful = require("beautiful")
local spawn = require("awful.spawn")
local watch = require("awful.widget.watch")
local wibox = require("wibox")
local naughty = require("naughty")

local GET_MPD_CMD = "mpc status"
local TOGGLE_MPD_CMD = "mpc toggle"
local START_MPD_CMD = "mpc play"
local PAUSE_MPD_CMD = "mpc pause"
local STOP_MPD_CMD = "mpc stop"
local PREV_MPD_CMD = "mpc prev"
local NEXT_MPD_CMD = "mpc next"
local MPDCLIENT_CMD = "sonata"

--local PATH_TO_ICONS = "/usr/share/icons/Arc/actions/24/player_"
local PATH_TO_ICONS = "/home/raph/.config/awesome/themes/myzenburn/"

local PAUSE_ICON_NAME = PATH_TO_ICONS .. "pause.png"
local PLAY_ICON_NAME = PATH_TO_ICONS .. "play.png"
local STOP_ICON_NAME = PATH_TO_ICONS .. "stop.png"
--local PAUSE_ICON_NAME = PATH_TO_ICONS .. "/actions/24/player_pause.png"
--local PLAY_ICON_NAME = PATH_TO_ICONS .. "/actions/24/player_play.png"
--local STOP_ICON_NAME = PATH_TO_ICONS .. "/actions/24/player_stop.png"

local icon = wibox.widget { 
        id = "icon",
        widget = wibox.widget.imagebox,
        image = PLAY_ICON_NAME
    }
local mirrored_icon = wibox.container.mirror(icon, { horizontal = true })

local mpdarc = wibox.widget {
    mirrored_icon,
    max_value = 1,
    value = 0.75,
    thickness = 2,
    start_angle = 4.71238898, -- 2pi*3/4
    forced_height = 32,
    forced_width = 32,
    rounded_edge = true,
    bg = "#ffffff11",
    paddings = 0,
    widget = wibox.container.arcchart
}

local mpdarc_widget = wibox.container.mirror(mpdarc, { horizontal = true })

local update_graphic = function(widget, stdout, _, _, _)
    stdout = string.gsub(stdout, "\n", "")
    local mpdstatus = string.match(stdout, "%[(%a+)%]")
    local mpdpercent = string.match(stdout, "(%d?%d)%%")
    if mpdstatus == "playing" then 
      icon.image = PLAY_ICON_NAME
      widget.colors = { beautiful.widget_main_color }
      widget.value = tonumber((100-mpdpercent)/100)
    elseif mpdstatus == "paused" then 
      icon.image = PAUSE_ICON_NAME
      widget.colors = { beautiful.widget_main_color }
      widget.value = tonumber((100-mpdpercent)/100)
    else
      icon.image = STOP_ICON_NAME
      widget.value = 1
      --widget.colors = { beautiful.widget_red }
    end
end

mpdarc:connect_signal("button::press", function(_, _, _, button)
    if (button == 1) then awful.spawn(TOGGLE_MPD_CMD, false)      -- left click
    elseif (button == 2) then awful.spawn(MPDCLIENT_CMD, false) -- middle click
    elseif (button == 3) then awful.spawn(STOP_MPD_CMD, false)
    elseif (button == 4) then awful.spawn(NEXT_MPD_CMD, false)  -- scroll up
    elseif (button == 5) then awful.spawn(PREV_MPD_CMD, false)  -- scroll down
    end

    spawn.easy_async(GET_MPD_CMD, function(stdout, stderr, exitreason, exitcode)
        update_graphic(mpdarc, stdout, stderr, exitreason, exitcode)
    end)
end)

local notification
function show_MPD_status()
    spawn.easy_async(GET_MPD_CMD,
        function(stdout, _, _, _)
            notification = naughty.notify {
                text = stdout,
                title = "MPD",
                timeout = 5,
                hover_timeout = 0.5,
                width = 600,
            }
        end)
end

mpdarc:connect_signal("mouse::enter", function() show_MPD_status() end)
mpdarc:connect_signal("mouse::leave", function() naughty.destroy(notification) end)

watch(GET_MPD_CMD, 1, update_graphic, mpdarc)

return mpdarc_widget
