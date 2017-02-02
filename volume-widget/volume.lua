local wibox = require("wibox")
local awful = require("awful")

function update_volume()
	awful.spawn.easy_async([[bash -c 'amixer -D pulse sget Master']], 
		function(stdout, stderr, reason, exit_code)   
			local volume = string.match(stdout, "(%d?%d?%d)%%")
			volume = tonumber(string.format("% 3d", volume))
			local volume_icon_name

			if (volume >= 0 and volume < 20) then volume_icon_name="audio-volume-none-panel"
			elseif (volume >= 20 and volume < 40) then volume_icon_name="audio-volume-zero-panel"
			elseif (volume >= 40 and volume < 60) then volume_icon_name="audio-volume-low-panel"
			elseif (volume >= 60 and volume < 80) then volume_icon_name="audio-volume-medium-panel"
			elseif (volume >= 80 and volume <= 100) then volume_icon_name="audio-volume-high-panel"
			end
		volume_icon:set_image("/usr/share/icons/Arc/panel/22/" .. volume_icon_name .. ".svg")
	end)
end


volume_icon = wibox.widget.imagebox()

mytimer = timer({ timeout = 0.2 })
mytimer:connect_signal("timeout", function () update_volume() end)
mytimer:start()