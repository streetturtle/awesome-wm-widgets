-------------------------------------------------
-- Volume Arc Widget for Awesome Window Manager
-- Shows the current volume level
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/volumearc-widget

-- @author Pavel Makhov
-- @copyright 2017 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local beautiful = require("beautiful")
local spawn = require("awful.spawn")
local watch = require("awful.widget.watch")
local wibox = require("wibox")

local GET_VOLUME_CMD = 'amixer -D pulse sget Master'
--local INC_VOLUME_CMD = 'amixer -D pulse sset Master 5%+'
local INC_VOLUME_CMD = 'amixer -q -c 0 sset Master 2dB+'
--local DEC_VOLUME_CMD = 'amixer -D pulse sset Master 5%-'
local DEC_VOLUME_CMD = 'amixer -q -c 0 sset Master 2dB-'
local TOG_VOLUME_CMD = 'amixer -D pulse sset Master toggle'
local MIXER_CMD = 'urxvtc -e bash -c "alsamixer -c0"'

local text = wibox.widget {
    id = "txt",
    font = "Play 12",
    widget = wibox.widget.textbox
}
-- mirror the text, because the whole widget will be mirrored after
--local mirrored_text = wibox.container.margin(wibox.container.mirror(text, { horizontal = true }))
--mirrored_text.right = 2 -- pour centrer le texte dans le rond
--
local mirrored_text = wibox.container.mirror(text, { horizontal = true })

-- mirrored text with background
local mirrored_text_with_background = wibox.container.background(mirrored_text)

local volumearc = wibox.widget {
    mirrored_text_with_background,
    max_value = 1,
    start_angle = 4.71238898, -- 2pi*3/4
    thickness = 2,
    forced_height = 32,
    forced_width = 32,
    rounded_edge = true,
    bg = "#ffffff11",
    paddings = 4,
    widget = wibox.container.arcchart
}

--local volumearc_widget = wibox.container.margin(wibox.container.mirror(volumearc, { horizontal = true }))
--volumearc_widget.margins = 4
--local mirrored_text = wibox.container.margin(wibox.container.mirror(text, { horizontal = true }))
--mirrored_text.right = 2 -- pour centrer le texte dans le rond
local volumearc_widget = wibox.container.mirror(volumearc, { horizontal = true })

local update_graphic = function(widget, stdout, _, _, _)
    local mute = string.match(stdout, "%[(o%D%D?)%]")
    local volume1 = string.match(stdout, "(%d?%d?%d)%%")
    volume = tonumber(string.format("% 3d", volume1))
    volumepad = tonumber(string.format("% 3d", volume1))

    widget.value = volume / 100;
    if mute == "off" then
        widget.colors = { beautiful.widget_red }
    else
        widget.colors = { beautiful.widget_main_color }
    end
    if volume == 100 then
      text.text = string.format("%03d", volumepad)
    else
      text.text = string.format("%02d", volumepad)
      text.font = "Play 11"
    end
end

volumearc:connect_signal("button::press", function(_, _, _, button)
    if (button == 4) then awful.spawn(INC_VOLUME_CMD, false)
    elseif (button == 5) then awful.spawn(DEC_VOLUME_CMD, false)
    elseif (button == 1) then awful.spawn(TOG_VOLUME_CMD, false)
    elseif (button == 3) then awful.spawn(MIXER_CMD, false)
    end

    spawn.easy_async(GET_VOLUME_CMD, function(stdout, stderr, exitreason, exitcode)
        update_graphic(volumearc, stdout, stderr, exitreason, exitcode)
    end)
end)

watch(GET_VOLUME_CMD, 1, update_graphic, volumearc)

return volumearc_widget
