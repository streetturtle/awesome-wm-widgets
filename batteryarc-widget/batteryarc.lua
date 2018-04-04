local awful = require("awful")
local beautiful = require("beautiful")
local naughty = require("naughty")
local wibox = require("wibox")
local watch = require("awful.widget.watch")

local HOME = os.getenv("HOME")

-- only text
local text = wibox.widget {
    id = "txt",
    font = "Play 8",
    widget = wibox.widget.textbox
}

-- mirror the text, because the whole widget will be mirrored after
local mirrored_text = wibox.container.mirror(text, { horizontal = true })

-- mirrored text with background
local mirrored_text_with_background = wibox.container.background(mirrored_text)

local batteryarc = wibox.widget {
    mirrored_text_with_background,
    max_value = 1,
    rounded_edge = true,
    thickness = 2,
    start_angle = 4.71238898, -- 2pi*3/4
    forced_height = 32,
    forced_width = 32,
    bg = "#ffffff11",
    paddings = 4,
    widget = wibox.container.arcchart,
    set_value = function(self, value)
        self.value = value
    end,
}

-- mirror the widget, so that chart value increases clockwise
local batteryarc_widget = wibox.container.mirror(batteryarc, { horizontal = true })

watch("acpi", 30,
    function(widget, stdout, stderr, exitreason, exitcode)
        local batteryType
        local _, status, charge_str, time = string.match(stdout, '(.+): (%a+), (%d?%d%d)%%,? ?.*')
        local charge = tonumber(charge_str)
        widget.value = charge / 100
        if status == 'Charging' then
            mirrored_text_with_background.fg = beautiful.widget_green
            --mirrored_text_with_background.fg = beautiful.widget_black
        else
            mirrored_text_with_background.bg = beautiful.widget_transparent
            mirrored_text_with_background.fg = beautiful.widget_main_color
        end

        if charge < 10 then
            batteryarc.colors = { beautiful.widget_red }
            if status ~= 'Charging' then
                show_battery_warning()
            end
        elseif charge > 10 and charge < 25 then
            batteryarc.colors = { beautiful.widget_yellow }
        elseif charge < 100 then
            batteryarc.colors = { beautiful.widget_green }
        else
            batteryarc.colors = { beautiful.widget_main_color }
        end

        if charge == 100 then
          --text.text = string.format("%03d", charge)
          text.text = charge
          text.font = "Play 8"
        else
          text.text = charge
          text.font = "Play 12"
        end
    end,
    batteryarc)

-- Popup with battery info
-- One way of creating a pop-up notification - naughty.notify
local notification
function show_battery_status()
    awful.spawn.easy_async([[bash -c 'acpi']],
        function(stdout, _, _, _)
            notification = naughty.notify {
                text = stdout,
                title = "Battery status",
                timeout = 5,
                hover_timeout = 0.5,
                width = 200,
            }
        end)
end

batteryarc:connect_signal("mouse::enter", function() show_battery_status() end)
batteryarc:connect_signal("mouse::leave", function() naughty.destroy(notification) end)

-- Alternative to naughty.notify - tooltip. You can compare both and choose the preferred one

--battery_popup = awful.tooltip({objects = {battery_widget}})

-- To use colors from beautiful theme put
-- following lines in rc.lua before require("battery"):
-- beautiful.tooltip_fg = beautiful.fg_normal
-- beautiful.tooltip_bg = beautiful.bg_normal

--[[ Show warning notification ]]
function show_battery_warning()
    naughty.notify {
        icon = HOME .. "/.config/awesome/nichosi.png",
        icon_size = 100,
        text = "Huston, we have a problem",
        title = "Battery is dying",
        timeout = 5,
        hover_timeout = 0.5,
        position = "bottom_right",
        bg = "#F06060",
        fg = "#EEE9EF",
        width = 300,
    }
end

return batteryarc_widget
