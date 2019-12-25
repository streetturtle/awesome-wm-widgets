-------------------------------------------------
-- Volume Widget for Awesome Window Manager
-- Shows the current volume level
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/volume-widget

-- @author Pavel Makhov
-- @copyright 2018 Pavel Makhov
-------------------------------------------------

local wibox = require("wibox")
local watch = require("awful.widget.watch")
local spawn = require("awful.spawn")
local naughty = require("naughty")
local gfs = require("gears.filesystem")
local dpi = require('beautiful').xresources.apply_dpi

local PATH_TO_ICONS = "/usr/share/icons/Arc/status/symbolic/"

local volume_widget = {}

local function worker(args)

    local args = args or {}

    local volume_audio_controller = args.volume_audio_controller or 'pulse'
    local display_notification = args.notification or 'false'
    local position = args.notification_position or "top_right"
    local device_arg = ''
    if volume_audio_controller == 'pulse' then
        device_arg = '-D pulse'
    end

    local GET_VOLUME_CMD = 'amixer ' .. device_arg .. ' sget Master'
    local INC_VOLUME_CMD = 'amixer ' .. device_arg .. ' sset Master 5%+'
    local DEC_VOLUME_CMD = 'amixer ' .. device_arg .. ' sset Master 5%-'
    local TOG_VOLUME_CMD = 'amixer ' .. device_arg .. ' sset Master toggle'

    if not gfs.dir_readable(PATH_TO_ICONS) then
        naughty.notify{
            title = "Volume Widget",
            text = "Folder with icons doesn't exist: " .. PATH_TO_ICONS,
            preset = naughty.config.presets.critical
        }
    end

    volume_widget = wibox.widget {
        {
            id = "icon",
            image = PATH_TO_ICONS .. "audio-volume-muted-symbolic.svg",
            resize = false,
            widget = wibox.widget.imagebox,
        },
        layout = wibox.container.margin(_, _, _, 3),
        set_image = function(self, path)
            self.icon.image = path
        end
    }

    local notification = {}
    local volume_icon_name="audio-volume-high-symbolic"

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
            naughty.destroy(notification)
            notification = naughty.notify{
                text =  get_notification_text(stdout),
                icon=PATH_TO_ICONS .. val .. ".svg",
                icon_size = dpi(16),
                title = "Volume",
                position = position,
                timeout = 0, hover_timeout = 0.5,
                width = 200,
            }
        end
        )
    end


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
        widget.image = PATH_TO_ICONS .. volume_icon_name .. ".svg"
        if display_notification then
            notification.iconbox.image = PATH_TO_ICONS .. volume_icon_name .. ".svg"
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
        end)
    end)

    if display_notification then
        volume_widget:connect_signal("mouse::enter", function() show_volume(volume_icon_name) end)
        volume_widget:connect_signal("mouse::leave", function() naughty.destroy(notification) end)
    end
    watch(GET_VOLUME_CMD, 1, update_graphic, volume_widget)

    return volume_widget
end

return setmetatable(volume_widget, { __call = function(_, ...) return worker(...) end })
