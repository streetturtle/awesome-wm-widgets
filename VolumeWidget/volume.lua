local wibox = require("wibox")
local awful = require("awful")

volume_widget = wibox.widget.imagebox()

function update_volume(widget)
  local fd = io.popen("amixer -D pulse sget Master")
  local status = fd:read("*all")
  fd:close()

  local volume = string.match(status, "(%d?%d?%d)%%")
  volume = tonumber(string.format("% 3d", volume))

  status = string.match(status, "%[(o[^%]]*)%]")

  if (volume >= 0 and volume < 10) then volumeLevel=1
    elseif (volume >= 10 and volume < 20) then volumeLevel=2
    elseif (volume >= 20 and volume < 30) then volumeLevel=3
    elseif (volume >= 30 and volume < 40) then volumeLevel=4
    elseif (volume >= 40 and volume < 50) then volumeLevel=5
    elseif (volume >= 50 and volume < 60) then volumeLevel=6
    elseif (volume >= 60 and volume < 70) then volumeLevel=7
    elseif (volume >= 70 and volume < 80) then volumeLevel=8
    elseif (volume >= 80 and volume <= 100) then volumeLevel=9
  end

  widget:set_image("/home/pashik/.config/awesome/volume-icons/" .. volumeLevel .. ".png")
end

update_volume(volume_widget)

mytimer = timer({ timeout = 0.2 })
mytimer:connect_signal("timeout", function () update_volume(volume_widget) end)
mytimer:start()