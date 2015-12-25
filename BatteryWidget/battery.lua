local wibox = require("wibox")
local awful = require("awful")
local naughty = require("naughty")

function showBatteryWidgetPopup()
  local save_offset = offset
  naughty.notify({
    text = awful.util.pread("acpi | cut -d, -f 2,3"),
    title = "Battery status",
    timeout = 5, hover_timeout = 0.5,
    width = 160,
  })
end

function showWarningWidgetPopup()
  local charge = tonumber(awful.util.pread("acpi | cut -d, -f 2 | egrep -o '[0-9]{1,3}'"))
  if (charge < 15) then 
    naughty.notify({
      text = "Huston, we have a problem",
      title = "Battery dying",
      timeout = 5, hover_timeout = 0.5,
      position = "bottom_right",
      bg = "#F06060",
      fg = "#EEE9EF",
      width = 200,
    })
  end
end

function showBatteryWidgetIcon()
    local charge = tonumber(awful.util.pread("acpi | cut -d, -f 2 | egrep -o '[0-9]{1,3}'"))
    local batteryType   

    if (charge >= 0 and charge < 20) then batteryType=20
    elseif (charge >= 20 and charge < 40) then batteryType=40
    elseif (charge >= 40 and charge < 60) then batteryType=60
    elseif (charge >= 60 and charge < 80) then batteryType=80
    elseif (charge >= 80 and charge <= 100) then batteryType=100
    end

    batteryIcon:set_image("/home/username/.config/awesome/battery-icons/" .. batteryType .. ".png")
end

batteryIcon = wibox.widget.imagebox()
showBatteryWidgetIcon()
batteryIcon:connect_signal("mouse::enter", function() showBatteryWidgetPopup() end)

-- timer to refresh battery icon
batteryWidgetTimer = timer({ timeout = 5 })  
batteryWidgetTimer:connect_signal("timeout",  function() showBatteryWidgetIcon() end)
batteryWidgetTimer:start()

-- timer to refresh battery warning
batteryWarningTimer = timer({ timeout = 50 })  
batteryWarningTimer:connect_signal("timeout",  function() showWarningWidgetPopup() end)
batteryWarningTimer:start()
