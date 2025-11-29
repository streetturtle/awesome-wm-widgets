-------------------------------------------------
-- Battery Widget for Awesome Window Manager
-- Shows the battery status using the ACPI tool
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/battery-widget

-- @author Pavel Makhov
-- @copyright 2017 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local wibox = require("wibox")
local gfs = require("gears.filesystem")
local dpi = require('beautiful').xresources.apply_dpi

-- acpi sample outputs
-- Battery 0: Discharging, 75%, 01:51:38 remaining
-- Battery 0: Charging, 53%, 00:57:43 until charged

local HOME = os.getenv("HOME")
local WIDGET_DIR = HOME .. '/.config/awesome/awesome-wm-widgets/battery-widget'
local widgets = {} -- holds all widget instances
local global_timer -- only one timer!
local global_last_warning

local battery_config = nil
local battery_widget = {}

local batteryType = "battery-good-symbolic"

local function update_all_widgets()
    awful.spawn.easy_async("acpi -i", function(stdout)
        local battery_info = {}
        local capacities = {}
        local should_warn = false
        for s in stdout:gmatch("[^\r\n]+") do
            -- Match a line with status and charge level
            local status, charge_str, _ = string.match(s, '.+: ([%a%s]+), (%d?%d?%d)%%,?(.*)')
            if status ~= nil then
                -- Enforce that for each entry in battery_info there is an
                -- entry in capacities of zero. If a battery has status
                -- "Unknown" then there is no capacity reported and we treat it
                -- as zero capactiy for later calculations.
                table.insert(battery_info, {status = status, charge = tonumber(charge_str)})
                table.insert(capacities, 0)
            end

            -- Match a line where capacity is reported
            local cap_str = string.match(s, '.+:.+last full capacity (%d+)')
            if cap_str ~= nil then
                capacities[#capacities] = tonumber(cap_str) or 0
            end
        end

        local capacity = 0
        local charge = 0
        local status
        for i, batt in ipairs(battery_info) do
            if capacities[i] ~= nil then
                if batt.charge >= charge then
                    status = batt.status -- use most charged battery status
                    -- this is arbitrary, and maybe another metric should be used
                end

                -- Adds up total (capacity-weighted) charge and total capacity.
                -- It effectively ignores batteries with status "Unknown" as we
                -- treat them with capacity zero.
                charge = charge + batt.charge * capacities[i]
                capacity = capacity + capacities[i]
            end
        end
        charge = charge / capacity

        if (charge >= 1 and charge < 15) then
            batteryType = "battery-empty%s-symbolic"
            should_warn = status ~= 'Charging'
        elseif (charge >= 15 and charge < 40) then batteryType = "battery-caution%s-symbolic"
        elseif (charge >= 40 and charge < 60) then batteryType = "battery-low%s-symbolic"
        elseif (charge >= 60 and charge < 80) then batteryType = "battery-good%s-symbolic"
        elseif (charge >= 80 and charge <= 100) then batteryType = "battery-full%s-symbolic"
        end

        if status == 'Charging' then
            batteryType = string.format(batteryType, '-charging')
        else
            batteryType = string.format(batteryType, '')
        end
        -- Send update to all widgets
        for _, w in ipairs(widgets) do
            w.icon:set_image(battery_config.path_to_icons .. batteryType .. ".svg")
            if battery_config.show_current_level then
                w.level.text = string.format('%d%%', charge)
            end
        end

        -- Handle notification
        if battery_config.enable_battery_warning and should_warn then
            if not global_last_warning or os.difftime(os.time(), global_last_warning) > 300 then
                global_last_warning = os.time()
                naughty.notify {
                  icon = battery_config.warning_msg_icon,
                  icon_size = 100,
                  text = battery_config.warning_msg_text,
                  title = battery_config.warning_msg_title,
                  timeout = 25, -- show the warning for a longer time
                  hover_timeout = 0.5,
                  position = battery_config.warning_msg_position,
                  bg = "#F06060",
                  fg = "#EEE9EF",
                  width = 300,
                  screen = mouse.screen
                }
            end
        end
    end)
end
local function remove_widget(icon_widget)
    for i, w in ipairs(widgets) do
        if w.icon == icon_widget then
            table.remove(widgets, i)
            break
        end
    end
end
local function worker(user_args)
    local args = user_args or {}
    if not battery_config then
      battery_config = {
        font = args.font or 'Play 8',
        path_to_icons = args.path_to_icons or "/usr/share/icons/Arc/status/symbolic/",
        show_current_level = args.show_current_level or false,
        warning_msg_title = args.warning_msg_title or 'Huston, we have a problem',
        warning_msg_text = args.warning_msg_text or 'Battery is dying',
        warning_msg_position = args.warning_msg_position or 'bottom_right',
        warning_msg_icon = args.warning_msg_icon or WIDGET_DIR .. '/spaceman.jpg',
        enable_battery_warning = args.enable_battery_warning ~= false,
        notification_position = args.notification_position or "top_right",
        timeout = args.timeout or 10
      }
    end
    local margin_left = args.margin_left or 0
    local margin_right = args.margin_right or 0

    local display_notification = args.display_notification or false
    local display_notification_onClick = args.display_notification_onClick or true
    local position = args.notification_position or "top_right"
    -- Only create the global timer once
    if not global_timer then
        global_timer = gears.timer {
            timeout = battery_config.timeout,
            call_now = true,
            autostart = true,
            callback = update_all_widgets
        }
    end

    if not gfs.dir_readable(battery_config.path_to_icons) then
        naughty.notify{
            title = "Battery Widget",
            text = "Folder with icons doesn't exist: " .. battery_config.path_to_icons,
            preset = naughty.config.presets.critical
        }
    end
    local imagebox = wibox.widget.imagebox()
    imagebox.resize = false

    local icon_widget = wibox.widget {
      imagebox,
      valign = 'center',
      layout = wibox.container.place,
    }
    local level_widget = wibox.widget {
        font = battery_config.font,
        widget = wibox.widget.textbox
    }
    battery_widget = wibox.widget {
        icon_widget,
        level_widget,
        layout = wibox.layout.fixed.horizontal,
      }
      table.insert(widgets, {icon = imagebox, level = level_widget})
      -- Popup with battery info
      -- One way of creating a pop-up notification - naughty.notify
      local notification
      local function show_battery_status(bat_type)
        awful.spawn.easy_async([[bash -c 'acpi']],
        function(stdout, _, _, _)
          naughty.destroy(notification)
          notification = naughty.notify{
            text =  stdout,
            title = "Battery status",
            icon = battery_config.path_to_icons .. bat_type .. ".svg",
            icon_size = dpi(16),
            position = position,
            timeout = 5, hover_timeout = 0.5,
            width = 200,
            screen = mouse.screen
          }
        end
        )
      end

      -- Alternative to naughty.notify - tooltip. You can compare both and choose the preferred one
      --battery_popup = awful.tooltip({objects = {battery_widget}})

      -- To use colors from beautiful theme put
      -- following lines in rc.lua before require("battery"):
      -- beautiful.tooltip_fg = beautiful.fg_normal
      -- beautiful.tooltip_bg = beautiful.bg_normal


      if display_notification then
        battery_widget:connect_signal("mouse::enter", function() show_battery_status(batteryType) end)
        battery_widget:connect_signal("mouse::leave", function() naughty.destroy(notification) end)
      elseif display_notification_onClick then
        battery_widget:connect_signal("button::press", function(_,_,_,button)
          if (button == 3) then show_battery_status(batteryType) end
        end)
        battery_widget:connect_signal("mouse::leave", function() naughty.destroy(notification) end)
      end
      battery_widget:connect_signal("widget::unmanage", function()
        remove_widget(imagebox)
      end)


    return wibox.container.margin(battery_widget, margin_left, margin_right)
end

return setmetatable(battery_widget, { __call = function(_, ...) return worker(...) end })
