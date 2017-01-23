local wibox = require("wibox")
local awful = require("awful")
local naughty = require("naughty")


batteryIcon = wibox.widget {
widget = wibox.widget.imagebox
}

function refresh_icon()
  awful.spawn.easy_async([[bash -c 'acpi | cut -d, -f 2 | egrep -o "[0-9]{1,3}"']], 
    function(stdout, stderr, reason, exit_code)   
      local batteryType
      local charge = tonumber(stdout)
      if (charge >= 0 and charge < 20) then 
        batteryType="battery-empty"
        show_battery_warning()
        elseif (charge >= 20 and charge < 40) then batteryType="battery-caution"
        elseif (charge >= 40 and charge < 60) then batteryType="battery-low"
        elseif (charge >= 60 and charge < 80) then batteryType="battery-good"
        elseif (charge >= 80 and charge <= 100) then batteryType="battery-full"
      end
      batteryIcon.image = "/usr/share/icons/Arc-Icons/panel/22/" .. batteryType .. ".svg"
    end)
end

function show_battery_status()
  awful.spawn.easy_async([[bash -c 'acpi | cut -d, -f 2,3']],
    function(stdout, stderr, reason, exit_code)   
      naughty.notify{
      text = stdout,
      title = "Battery status",
      timeout = 5, hover_timeout = 0.5,
      width = 200,
    }   
  end
  )
end

function show_battery_warning()
  naughty.notify{
  text = "Huston, we have a problem",
  title = "Battery is dying",
  timeout = 5, hover_timeout = 0.5,
  position = "bottom_right",
  bg = "#F06060",
  fg = "#EEE9EF",
  width = 200,
}
end

-- timer to refresh icon
local batteryWidgetTimer = timer({ timeout = 60 })  
batteryWidgetTimer:connect_signal("timeout",  function() refresh_icon() end)
batteryWidgetTimer:start()
batteryWidgetTimer:emit_signal("timeout")

-- popup with battery info
batteryIcon:connect_signal("mouse::enter", function() show_battery_status() end)