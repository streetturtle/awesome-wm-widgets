-------------------------------------------------
-- Battery Widget for Awesome Window Manager
-- Shows the battery status using the ACPI tool
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/battery-widget
--
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

-- Constants
local CRITICAL_BATTERY_LEVEL = 15
local LOW_BATTERY_LEVEL = 40
local MEDIUM_BATTERY_LEVEL = 60
local HIGH_BATTERY_LEVEL = 80
local WARNING_THRESHOLD_SECONDS = 300
local NOTIFICATION_TIMEOUT = 25
local MIN_TIMEOUT = 1
local MAX_TIMEOUT = 3600

-- Default configuration
local DEFAULT_CONFIG = {
    font = 'Play 8',
    path_to_icons = "/usr/share/icons/Arc/status/symbolic/",
    show_current_level = false,
    warning_msg_title = 'Houston, we have a problem',
    warning_msg_text = 'Battery is dying',
    warning_msg_position = 'bottom_right',
    warning_msg_icon = WIDGET_DIR .. '/spaceman.jpg',
    enable_battery_warning = true,
    notification_position = "top_right",
    timeout = 10,
    on_battery_low = nil,
    on_charging_state_changed = nil
}

-- Global state
local widgets = {} -- holds all widget instances
local global_timer -- only one timer!
local global_last_warning
local battery_config = nil
local icon_cache = {}
local last_charging_state = nil

-- Get battery icon type based on charge level and charging status
-- @param charge number: Battery charge percentage (0-100)
-- @param status string: Battery status (e.g., "Charging", "Discharging")
-- @return string: Icon name
local function get_battery_type(charge, status)
    local type_template
    if charge >= HIGH_BATTERY_LEVEL then
        type_template = "battery-full%s-symbolic"
    elseif charge >= MEDIUM_BATTERY_LEVEL then
        type_template = "battery-good%s-symbolic"
    elseif charge >= LOW_BATTERY_LEVEL then
        type_template = "battery-low%s-symbolic"
    elseif charge >= CRITICAL_BATTERY_LEVEL then
        type_template = "battery-caution%s-symbolic"
    else
        type_template = "battery-empty%s-symbolic"
    end

    local suffix = (status == 'Charging') and '-charging' or ''
    return string.format(type_template, suffix)
end

-- Get icon path with caching
-- @param battery_type string: Battery icon type
-- @return string: Full path to icon
local function get_icon_path(battery_type)
    if not icon_cache[battery_type] then
        icon_cache[battery_type] = battery_config.path_to_icons .. battery_type .. ".svg"
    end
    return icon_cache[battery_type]
end

-- Parse ACPI output to extract battery information
-- @param stdout string: ACPI command output
-- @return table: Battery info with status and charge for each battery
-- @return table: Capacities for each battery
local function parse_battery_info(stdout)
    local battery_info = {}
    local capacities = {}

    for s in stdout:gmatch("[^\r\n]+") do

        -- Try standard format: "Battery 0: Discharging, 75%, ..."
        local status, charge_str = string.match(s, '[Bb]attery%s*%d*:%s*([%a%s]+),%s*(%d+)%%')

        -- Try alternative format: "BAT0: Discharging, 75%, ..."
        if not status then
            status, charge_str = string.match(s, 'BAT%d+:%s*([%a%s]+),%s*(%d+)%%')
        end

        if status ~= nil then
            -- Trim whitespace from status
            status = status:match("^%s*(.-)%s*$")

            -- Enforce that for each entry in battery_info there is an
            -- entry in capacities of zero. If a battery has status
            -- "Unknown" then there is no capacity reported and we treat it
            -- as zero capacity for later calculations.
            table.insert(battery_info, {status = status, charge = tonumber(charge_str)})
            table.insert(capacities, 0)
        end

        -- Match a line where capacity is reported
        local cap_str = string.match(s, '.+:.+last full capacity (%d+)')
        if cap_str ~= nil then
            capacities[#capacities] = tonumber(cap_str) or 0
        end
    end

    return battery_info, capacities
end

-- Calculate aggregate charge across all batteries
-- Uses capacity-weighted average for multiple batteries
-- @param battery_info table: Battery information from parse_battery_info
-- @param capacities table: Battery capacities
-- @return number: Weighted average charge (0-100)
-- @return string: Status of the most charged battery
local function calculate_aggregate_charge(battery_info, capacities)
    local capacity = 0
    local charge = 0
    local status = "Unknown"  -- Default status
    local max_charge = 0

    for i, batt in ipairs(battery_info) do
        if capacities[i] ~= nil then
            if batt.charge >= max_charge then
                max_charge = batt.charge
                -- Use most charged battery status
                -- This is arbitrary, and maybe another metric should be used
                status = batt.status
            end

            -- Adds up total (capacity-weighted) charge and total capacity.
            -- It effectively ignores batteries with status "Unknown" as we
            -- treat them with capacity zero.
            charge = charge + batt.charge * capacities[i]
            capacity = capacity + capacities[i]
        end
    end

    -- Prevent division by zero
    charge = capacity > 0 and (charge / capacity) or 0


    return charge, status
end

-- Update widget display elements
-- @param charge number: Battery charge percentage
-- @param battery_type string: Battery icon type
local function update_widget_display(charge, battery_type)
    local icon_path = get_icon_path(battery_type)

    for _, w in ipairs(widgets) do
        w.icon:set_image(icon_path)
        if battery_config.show_current_level then
            w.level.text = string.format('%d%%', charge)
        end
    end

end

-- Check if battery warning should be shown
-- @param charge number: Battery charge percentage
-- @param status string: Battery status
local function check_battery_warning(charge, status)
    local should_warn = (charge >= 1 and charge < CRITICAL_BATTERY_LEVEL) and status ~= 'Charging'

    if battery_config.enable_battery_warning and should_warn then
        if not global_last_warning or os.difftime(os.time(), global_last_warning) > WARNING_THRESHOLD_SECONDS then
            global_last_warning = os.time()
            naughty.notify {
                icon = battery_config.warning_msg_icon,
                icon_size = 100,
                text = battery_config.warning_msg_text,
                title = battery_config.warning_msg_title,
                timeout = NOTIFICATION_TIMEOUT,
                hover_timeout = 0.5,
                position = battery_config.warning_msg_position,
                bg = "#F06060",
                fg = "#EEE9EF",
                width = 300,
                screen = mouse.screen
            }
            -- Call user callback if provided
            if battery_config.on_battery_low then
                battery_config.on_battery_low(charge)
            end
        end
    end
end

-- Check if charging state changed and trigger callback
-- @param status string: Current battery status
local function check_charging_state_change(status)
    local is_charging = (status == 'Charging')

    if last_charging_state ~= nil and last_charging_state ~= is_charging then

        if battery_config.on_charging_state_changed then
            battery_config.on_charging_state_changed(is_charging)
        end
    end

    last_charging_state = is_charging
end

-- Main update function that refreshes all widgets
local function update_all_widgets()
    awful.spawn.easy_async("acpi -i", function(stdout)
        -- Parse battery information
        local battery_info, capacities = parse_battery_info(stdout)

        if #battery_info == 0 then
            return
        end

        -- Calculate aggregate charge
        local charge, status = calculate_aggregate_charge(battery_info, capacities)

        -- Determine battery icon type
        local battery_type = get_battery_type(charge, status)

        -- Update all widget displays
        update_widget_display(charge, battery_type)

        -- Check for warnings
        check_battery_warning(charge, status)

        -- Check for charging state changes
        check_charging_state_change(status)
    end)
end

-- Remove a widget from the global registry
-- @param icon_widget widget: The icon widget to remove
local function remove_widget(icon_widget)
    -- Iterate backwards to safely remove during iteration
    for i = #widgets, 1, -1 do
        if widgets[i].icon == icon_widget then
            table.remove(widgets, i)
            break
        end
    end

    -- Stop timer if no widgets left
    if #widgets == 0 and global_timer then
        global_timer:stop()
        global_timer = nil
    end
end

-- Validate configuration parameters
-- @param config table: Configuration to validate
local function validate_config(config)
    if config.timeout and (config.timeout < MIN_TIMEOUT or config.timeout > MAX_TIMEOUT) then
        naughty.notify{
            title = "Battery Widget",
            text = string.format("Invalid timeout value: %d (must be between %d and %d)",
                                config.timeout, MIN_TIMEOUT, MAX_TIMEOUT),
            preset = naughty.config.presets.critical
        }
        config.timeout = DEFAULT_CONFIG.timeout
    end

    if config.path_to_icons and not gfs.dir_readable(config.path_to_icons) then
        naughty.notify{
            title = "Battery Widget",
            text = "Folder with icons doesn't exist: " .. config.path_to_icons,
            preset = naughty.config.presets.critical
        }
    end
end

-- Worker function to create battery widget
-- @param user_args table: User configuration
-- @return widget: Battery widget wrapped in margin container
local function worker(user_args)
    local args = user_args or {}

    -- Initialize global config only once
    if not battery_config then
        battery_config = {}
        for k, v in pairs(DEFAULT_CONFIG) do
            battery_config[k] = args[k] ~= nil and args[k] or v
        end

        validate_config(battery_config)
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

    local battery_widget = wibox.widget {
        icon_widget,
        level_widget,
        layout = wibox.layout.fixed.horizontal,
    }

    -- Register widget in global list
    table.insert(widgets, {icon = imagebox, level = level_widget})
    -- Popup with battery info
    local notification
    local function show_battery_status()
        awful.spawn.easy_async([[bash -c 'acpi']],
        function(stdout, _, _, _)
            naughty.destroy(notification)

            -- Get current battery type for icon
            local battery_info, capacities = parse_battery_info(stdout)
            if #battery_info > 0 then
                local charge, status = calculate_aggregate_charge(battery_info, capacities)
                local battery_type = get_battery_type(charge, status)

                notification = naughty.notify{
                    text = stdout,
                    title = "Battery status",
                    icon = get_icon_path(battery_type),
                    icon_size = dpi(16),
                    position = position,
                    timeout = 5,
                    hover_timeout = 0.5,
                    width = 200,
                    screen = mouse.screen
                }
            end
        end)
    end

    -- Alternative to naughty.notify - tooltip. You can compare both and choose the preferred one
    --battery_popup = awful.tooltip({objects = {battery_widget}})

    -- To use colors from beautiful theme put
    -- following lines in rc.lua before require("battery"):
    -- beautiful.tooltip_fg = beautiful.fg_normal
    -- beautiful.tooltip_bg = beautiful.bg_normal

    if display_notification then
        battery_widget:connect_signal("mouse::enter", function() show_battery_status() end)
        battery_widget:connect_signal("mouse::leave", function() naughty.destroy(notification) end)
    elseif display_notification_onClick then
        battery_widget:connect_signal("button::press", function(_, _, _, button)
            if (button == 3) then show_battery_status() end
        end)
        battery_widget:connect_signal("mouse::leave", function() naughty.destroy(notification) end)
    end

    battery_widget:connect_signal("widget::unmanage", function()
        remove_widget(imagebox)
    end)

    return wibox.container.margin(battery_widget, margin_left, margin_right)
end

return setmetatable({}, { __call = function(_, ...) return worker(...) end })
