-------------------------------------------------
-- Volume Widget for Awesome Window Manager
-- Shows the current volume level
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/volume-widget

-- @author Pavel Makhov
-- @copyright 2018 Pavel Makhov
-------------------------------------------------

local naughty = require("naughty")
local wibox = require("wibox")
local watch = require("awful.widget.watch")
local spawn = require("awful.spawn")
local dpi = require('beautiful').xresources.apply_dpi

local secrets = require("awesome-wm-widgets.secrets")

local path_to_icons = "/usr/share/icons/Arc/status/symbolic/"

local device_arg
if secrets.volume_audio_controller == 'pulse' then
	device_arg = '-D pulse'
else
	device_arg = ''
end

local GET_VOLUME_CMD = 'amixer ' .. device_arg .. ' sget Master'
local INC_VOLUME_CMD = 'amixer ' .. device_arg .. ' sset Master 5%+'
local DEC_VOLUME_CMD = 'amixer ' .. device_arg .. ' sset Master 5%-'
local TOG_VOLUME_CMD = 'amixer ' .. device_arg .. ' sset Master toggle'


local volume_widget = wibox.widget {
    {
        id = "icon",
        image = path_to_icons .. "audio-volume-muted-symbolic.svg",
        resize = false,
        widget = wibox.widget.imagebox,
    },
    layout = wibox.container.margin(_, _, _, 3),
    set_image = function(self, path)
        self.icon.image = path
    end
}

local notification
local function get_notification_text(txt)
    local mute = string.match(txt, "%[(o%a%a?)%]")
    local volume = string.match(txt, "(%d?%d?%d)%%")
    volume = tonumber(string.format("% 3d", volume))
    if mute == "off" then
        return volume.."% <span color=\"red\"><b>Mute</b></span>"
    else
        return volume .."%"
    end
end
local function show_volume(val)
    spawn.easy_async(GET_VOLUME_CMD,
        function(stdout, _, _, _)
            notification = naughty.notify{
                text =  get_notification_text(stdout),
                icon=path_to_icons .. val .. ".svg",
                icon_size = dpi(16),
                title = "Volume",
                position="top_right",
                timeout = 1.5, hover_timeout = 0.5,
                screen = mouse.screen,
                width = 200,
            }
        end
    )
end

local volume_icon_name

local update_graphic = function(widget, stdout, _, _, _)
    local mute = string.match(stdout, "%[(o%D%D?)%]")
    local volume = string.match(stdout, "(%d?%d?%d)%%")
    volume = tonumber(string.format("% 3d", volume))
    if mute == "off" then volume_icon_name="audio-volume-muted-symbolic_red"
    elseif (volume >= 0 and volume < 25) then volume_icon_name="audio-volume-muted-symbolic"
    elseif (volume < 50) then volume_icon_name="audio-volume-low-symbolic"
    elseif (volume < 75) then volume_icon_name="audio-volume-medium-symbolic"
    elseif (volume <= 100) then volume_icon_name="audio-volume-high-symbolic"
    end
    widget.image = path_to_icons .. volume_icon_name .. ".svg"
    if notification then
        naughty.replace_text(notification, "Volume", get_notification_text(stdout))
    end

end

--[[ allows control volume level by:
- clicking on the widget to mute/unmute
- scrolling when cursor is over the widget
]]
volume_widget:connect_signal("button::press", function(_,_,_,button)
    if (button == 4)     then spawn(INC_VOLUME_CMD, false)
    elseif (button == 5) then spawn(DEC_VOLUME_CMD, false)
    elseif (button == 1) then spawn(TOG_VOLUME_CMD, false)
    end

    spawn.easy_async(GET_VOLUME_CMD, function(stdout, stderr, exitreason, exitcode)
        update_graphic(volume_widget, stdout, stderr, exitreason, exitcode)
        naughty.reset_timeout(notification, 1)
    end)
end)

watch(GET_VOLUME_CMD, 1, update_graphic, volume_widget)
volume_widget:connect_signal("mouse::enter", function() show_volume(volume_icon_name) end)
volume_widget:connect_signal("mouse::leave", function() naughty.destroy(notification) end)

return volume_widget
