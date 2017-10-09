local wibox = require("wibox")
local awful = require("awful")
local naughty = require("naughty")
local watch = require("awful.widget.watch")

-- acpi sample outputs
-- Battery 0: Discharging, 75%, 01:51:38 remaining
-- Battery 0: Charging, 53%, 00:57:43 until charged

local PATH_TO_ICONS = "/usr/share/icons/Arc/status/symbolic/"
local USERNAME = os.getenv("USER")

battery_widget = wibox.widget {
    {
        id = "icon",
        widget = wibox.widget.imagebox,
        resize = false
    },
    layout = wibox.container.margin(_, 0, 0, 3),
    set_image = function(self, path)
        self.icon.image = path
    end
}

watch(
    "acpi", 10,
    function(widget, stdout, stderr, exitreason, exitcode)
        local batteryType
        local _, status, charge_str, time = string.match(stdout, '(.+): (%a+), (%d?%d%d)%%,? ?.*')
        local charge = tonumber(charge_str)
        if (charge >= 0 and charge < 15) then
	   batteryType="battery-empty%s-symbolic"
	   if status ~= 'Charging' then
	      show_battery_warning()
	   end
        elseif (charge >= 15 and charge < 40) then batteryType="battery-caution%s-symbolic"
        elseif (charge >= 40 and charge < 60) then batteryType="battery-low%s-symbolic"
        elseif (charge >= 60 and charge < 80) then batteryType="battery-good%s-symbolic"
        elseif (charge >= 80 and charge <= 100) then batteryType="battery-full%s-symbolic"
        end
        if status == 'Charging' then
            batteryType = string.format(batteryType,'-charging')
        else
            batteryType = string.format(batteryType,'')
        end
        widget.image = PATH_TO_ICONS .. batteryType .. ".svg"

        -- Update popup text
        -- TODO: Filter long lines
        -- battery_popup.text = string.gsub(stdout, "\n$", "")
    end,
    battery_widget
)

-- Popup with battery info
-- One way of creating a pop-up notification - naughty.notify
local notification
function show_battery_status()
    awful.spawn.easy_async([[bash -c 'acpi']],
        function(stdout, _, _, _)
            notification = naughty.notify{
                text =  stdout,
                title = "Battery status",
                timeout = 5, hover_timeout = 0.5,
                width = 200,
            }
        end
    )
end
battery_widget:connect_signal("mouse::enter", function() show_battery_status() end)
battery_widget:connect_signal("mouse::leave", function() naughty.destroy(notification) end)

-- Alternative to naughty.notify - tooltip. You can compare both and choose the preferred one

--battery_popup = awful.tooltip({objects = {battery_widget}})

-- To use colors from beautiful theme put
-- following lines in rc.lua before require("battery"):
-- beautiful.tooltip_fg = beautiful.fg_normal
-- beautiful.tooltip_bg = beautiful.bg_normal

--[[ Show warning notification ]]
function show_battery_warning()
    naughty.notify{
        icon = "/home/" .. USERNAME .. "/.config/awesome/nichosi.png",
        icon_size=100,
        text = "Huston, we have a problem",
        title = "Battery is dying",
        timeout = 5, hover_timeout = 0.5,
        position = "bottom_right",
        bg = "#F06060",
        fg = "#EEE9EF",
        width = 300,
    }
end
