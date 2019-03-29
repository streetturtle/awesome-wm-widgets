-------------------------------------------------
-- Battery Arc Widget for Awesome Window Manager
-- Shows the battery level of the laptop
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/batteryarc-widget

-- @author Pavel Makhov
-- @copyright 2019 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local beautiful = require("beautiful")
local naughty = require("naughty")
local wibox = require("wibox")
local watch = require("awful.widget.watch")

local HOME = os.getenv("HOME")

local text = wibox.widget {
    id = "txt",
    font = "Play 6",
    align  = 'center',  -- align the text
    valign = 'center',
    widget = wibox.widget.textbox
}

local text_with_background = wibox.container.background(text)

local batteryarc = wibox.widget {
    text_with_background,
    max_value = 1,
    rounded_edge = true,
    thickness = 2,
    start_angle = 4.71238898, -- 2pi*3/4
    forced_height = 18,
    forced_width = 18,
    bg = "#ffffff11",
    paddings = 2,
    widget = wibox.container.arcchart,
    set_value = function(self, value)
        self.value = value
    end,
}

local last_battery_check = os.time()

watch("acpi -i", 10,
        function(widget, stdout)
            local batteryType

            local battery_info = {}
            local capacities = {}
            for s in stdout:gmatch("[^\r\n]+") do
                local status, charge_str, time = string.match(s, '.+: (%a+), (%d?%d?%d)%%,?.*')
                if string.match(s, 'rate information') then
                    -- ignore such line
                elseif status ~= nil then
                    table.insert(battery_info, {status = status, charge = tonumber(charge_str)})
                else
                    local cap_str = string.match(s, '.+:.+last full capacity (%d+)')
                    table.insert(capacities, tonumber(cap_str))
                end
            end

            local capacity = 0
            for i, cap in ipairs(capacities) do
                capacity = capacity + cap
            end

            local charge = 0
            local status
            for i, batt in ipairs(battery_info) do
                if batt.charge >= charge then
                    -- use most charged battery status. This is arbitrary, and maybe another metric should be used
                    status = batt.status
                end

                charge = charge + batt.charge * capacities[i]
            end

            local charge_percentage
            if capacity > 5 then
                charge = charge / capacity
                charge_percentage = charge / 100
            else
                -- when widget.value is < 0.04, the widget shows a full circle (as widget.value=1)
                charge_percentage = 0.05
            end

            widget.value = charge / 100

            if status == 'Charging' then
                text_with_background.bg = beautiful.widget_green
                text_with_background.fg = beautiful.widget_black
            else
                text_with_background.bg = beautiful.widget_transparent
                text_with_background.fg = beautiful.widget_main_color
            end

            --- if battery is fully charged (100) there is not enough place for three digits, so we don't show any text
            text.text = charge == 100
                    and ''
                    or string.format('%d', charge)

            if charge < 15 then
                batteryarc.colors = { beautiful.widget_red }
                if status ~= 'Charging' and os.difftime(os.time(), last_battery_check) > 300 then
                    -- if 5 minutes have elapsed since the last warning
                    last_battery_check = os.time()

                    show_battery_warning()
                end
            elseif charge > 15 and charge < 40 then
                batteryarc.colors = { beautiful.widget_yellow }
            else
                batteryarc.colors = { beautiful.widget_main_color }
            end
        end,
        batteryarc)

-- Popup with battery info
-- One way of creating a pop-up notification - naughty.notify
local notification
function show_battery_status()
    awful.spawn.easy_async([[bash -c 'acpi']],
            function(stdout, _, _, _)
                naughty.destroy(notification)
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
        icon = HOME .. "/.config/awesome/awesome-wm-widgets/batteryarc-widget/spaceman.jpg",
        icon_size = 100,
        text = "Battery is dying", -- switch text and title
        title = "Huston, we have a problem",
        timeout = 25,   -- show the warning for a longer time
        hover_timeout = 0.5,
        position = "bottom_right",
        bg = "#F06060",
        fg = "#EEE9EF",
        width = 300,
    }
end

return batteryarc
