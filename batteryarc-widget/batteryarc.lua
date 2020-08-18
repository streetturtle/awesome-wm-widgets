-------------------------------------------------
-- Battery Arc Widget for Awesome Window Manager
-- Shows the battery level of the laptop
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/batteryarc-widget

-- @author Pavel Makhov
-- @copyright 2020 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local beautiful = require("beautiful")
local naughty = require("naughty")
local wibox = require("wibox")
local watch = require("awful.widget.watch")

local HOME = os.getenv("HOME")

local widget = {}

local function worker(args)

    local args = args or {}

    local font = args.font or 'Play 6'
    local arc_thickness = args.arc_thickness or 2
    local show_current_level = args.show_current_level or false
    local size = args.size or 18

    local main_color = args.main_color or beautiful.fg_color
    local bg_color = args.bg_color or '#ffffff11'
    local low_level_color = args.low_level_color or '#e53935'
    local medium_level_color = args.medium_level_color or '#c0ca33'
    local charging_color = args.charging_color or '#43a047'

    local warning_msg_title = args.warning_msg_title or 'Huston, we have a problem'
    local warning_msg_text = args.warning_msg_text or 'Battery is dying'
    local warning_msg_position = args.warning_msg_position or 'bottom_right'
    local warning_msg_icon = args.warning_msg_icon or HOME .. '/.config/awesome/awesome-wm-widgets/batteryarc-widget/spaceman.jpg'
    local enable_battery_warning = args.enable_battery_warning
    if enable_battery_warning == nil then
        enable_battery_warning = true
    end

    local text = wibox.widget {
        font = font,
        align = 'center',
        valign = 'center',
        widget = wibox.widget.textbox
    }

    local text_with_background = wibox.container.background(text)

    widget = wibox.widget {
        text_with_background,
        max_value = 100,
        rounded_edge = true,
        thickness = arc_thickness,
        start_angle = 4.71238898, -- 2pi*3/4
        forced_height = size,
        forced_width = size,
        bg = bg_color,
        paddings = 2,
        widget = wibox.container.arcchart
    }

    local last_battery_check = os.time()

    local function update_widget(widget, stdout)
        local charge = 0
        local status
        for s in stdout:gmatch("[^\r\n]+") do
            local cur_status, charge_str, time = string.match(s, '.+: (%a+), (%d?%d?%d)%%,?(.*)')
            if cur_status ~= nil and charge_str ~=nil then
                local cur_charge = tonumber(charge_str)
                if cur_charge > charge then
                    status = cur_status
                    charge = cur_charge
                end
            end
        end

        widget.value = charge

        if status == 'Charging' then
            text_with_background.bg = charging_color
            text_with_background.fg = '#000000'
        else
            text_with_background.bg = '#00000000'
            text_with_background.fg = main_color
        end

        if show_current_level == true then
            --- if battery is fully charged (100) there is not enough place for three digits, so we don't show any text
            text.text = charge == 100
                    and ''
                    or string.format('%d', charge)
        else
            text.text = ''
        end

        if charge < 15 then
            widget.colors = { low_level_color }
            if enable_battery_warning and status ~= 'Charging' and os.difftime(os.time(), last_battery_check) > 300 then
                -- if 5 minutes have elapsed since the last warning
                last_battery_check = os.time()

                show_battery_warning()
            end
        elseif charge > 15 and charge < 40 then
            widget.colors = { medium_level_color }
        else
            widget.colors = { main_color }
        end
    end

    watch("acpi", 10, update_widget, widget)

    -- Popup with battery info
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

    widget:connect_signal("mouse::enter", function()
        show_battery_status()
    end)
    widget:connect_signal("mouse::leave", function()
        naughty.destroy(notification)
    end)

    --[[ Show warning notification ]]
    function show_battery_warning()
        naughty.notify {
            icon = warning_msg_icon,
            icon_size = 100,
            text = warning_msg_text,
            title = warning_msg_title,
            timeout = 25, -- show the warning for a longer time
            hover_timeout = 0.5,
            position = warning_msg_position,
            bg = "#F06060",
            fg = "#EEE9EF",
            width = 300,
        }
    end

    return widget

end

return setmetatable(widget, { __call = function(_, ...)
    return worker(...)
end })
