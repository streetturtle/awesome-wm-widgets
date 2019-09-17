-------------------------------------------------
-- Brightness Widget for Awesome Window Manager
-- Shows the brightness level of the laptop display
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/widget-widget

-- @author Pavel Makhov
-- @copyright 2019 Pavel Makhov
-------------------------------------------------

local wibox = require("wibox")
local watch = require("awful.widget.watch")
local spawn = require("awful.spawn")
local beautiful = require("beautiful")

local PATH_TO_ICON = "/usr/share/icons/Arc/status/symbolic/display-brightness-symbolic.svg"
local GET_BRIGHTNESS_CMD = "light -G" -- "xbacklight -get"
local INC_BRIGHTNESS_CMD = "light -A 5" -- "xbacklight -inc 5"
local DEC_BRIGHTNESS_CMD = "light -U 5" -- "xbacklight -dec 5"

local widget = {}

local function worker(args)

    local args = args or {}

    local get_brightness_cmd = args.get_brightness_cmd or GET_BRIGHTNESS_CMD
    local inc_brightness_cmd = args.inc_brightness_cmd or INC_BRIGHTNESS_CMD
    local dec_brightness_cmd = args.dec_brightness_cmd or DEC_BRIGHTNESS_CMD
    local color = args.color or beautiful.fg_color
    local path_to_icon = args.path_to_icon or PATH_TO_ICON

    local icon = {
        id = "icon",
        image = path_to_icon,
        resize = true,
        widget = wibox.widget.imagebox,
    }

    widget = wibox.widget {
        icon,
        max_value = 1,
        thickness = 2,
        start_angle = 4.71238898, -- 2pi*3/4
        forced_height = 18,
        forced_width = 18,
        bg = "#ffffff11",
        paddings = 2,
        colors = {color},
        widget = wibox.container.arcchart
    }

    local update_widget = function(widget, stdout)
        local brightness_level = string.match(stdout, "(%d?%d?%d?)")
        brightness_level = tonumber(string.format("% 3d", brightness_level))

        widget.value = brightness_level / 100;
    end,

    widget:connect_signal("button::press", function(_, _, _, button)
        if (button == 4) then
            spawn(inc_brightness_cmd, false)
        elseif (button == 5) then
            spawn(dec_brightness_cmd, false)
        end
    end)

    watch(get_brightness_cmd, 1, update_widget, widget)

    return widget
end

return setmetatable(widget, { __call = function(_, ...)
    return worker(...)
end })
