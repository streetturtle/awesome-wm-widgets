local awful = require("awful")
local wibox = require("wibox")
local watch = require("awful.widget.watch")
local spawn = require("awful.spawn")

local path_to_icons = "/usr/share/icons/Arc/status/symbolic/"
local request_command = 'amixer -D pulse sget Master'

volume_widget = wibox.widget {
    {
        id = "icon",
   	image = path_to_icons .. "audio-volume-muted-symbolic.svg",
	resize = false,
        widget = wibox.widget.imagebox,
    },
    layout = wibox.container.margin(brightness_icon, 0, 0, 3),
    set_image = function(self, path)
        self.icon.image = path
    end
}

local update_graphic = function(widget, stdout, stderr, reason, exit_code)
    local mute = string.match(stdout, "%[(o%D%D?)%]")
    local volume = string.match(stdout, "(%d?%d?%d)%%")
    volume = tonumber(string.format("% 3d", volume))
    local volume_icon_name
    if mute == "off"                     then volume_icon_name="audio-volume-muted-symbolic"
    elseif (volume >= 0 and volume < 25) then volume_icon_name="audio-volume-muted-symbolic"
    elseif (volume < 50)                 then volume_icon_name="audio-volume-low-symbolic"
    elseif (volume < 75)                 then volume_icon_name="audio-volume-medium-symbolic"
    elseif (volume <= 100)               then volume_icon_name="audio-volume-high-symbolic"
    end
    widget.image = path_to_icons .. volume_icon_name .. ".svg"
end

--[[ allows control volume level by:
- clicking on the widget to mute/unmute
- scrolling when curson is over the widget
]]
volume_widget:connect_signal("button::press", function(_,_,_,button)
    if (button == 4)     then awful.spawn("amixer -D pulse sset Master 5%+", false)
    elseif (button == 5) then awful.spawn("amixer -D pulse sset Master 5%-", false)
    elseif (button == 1) then awful.spawn("amixer -D pulse sset Master toggle", false)
    end
    
    spawn.easy_async(request_command, function(stdout, stderr, exitreason, exitcode)
        update_graphic(volume_widget, stdout, stderr, exitreason, exitcode)
    end)
end)

watch(request_command, 1, update_graphic, volume_widget)
