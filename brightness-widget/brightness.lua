-------------------------------------------------
-- Brightness Widget for Awesome Window Manager
-- Shows the brightness level of the laptop display
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/brightness-widget

-- @author Pavel Makhov
-- @copyright 2017-2019 Pavel Makhov
-------------------------------------------------

local wibox = require("wibox")
local watch = require("awful.widget.watch")
local spawn = require("awful.spawn")

local PATH_TO_ICON = "/usr/share/icons/Arc/status/symbolic/display-brightness-symbolic.svg"
local GET_BRIGHTNESS_CMD = "light -G"   -- "xbacklight -get"
local INC_BRIGHTNESS_CMD = "light -A 5" -- "xbacklight -inc 5"
local DEC_BRIGHTNESS_CMD = "light -U 5" -- "xbacklight -dec 5"

local brightness_widget = {}

local function worker(user_args)

    local args = user_args or {}

    local get_brightness_cmd = args.get_brightness_cmd or GET_BRIGHTNESS_CMD
    local inc_brightness_cmd = args.inc_brightness_cmd or INC_BRIGHTNESS_CMD
    local dec_brightness_cmd = args.dec_brightness_cmd or DEC_BRIGHTNESS_CMD
    local path_to_icon = args.path_to_icon or PATH_TO_ICON
    local font = args.font or 'Play 9'
    local timeout = args.timeout or 1

    local brightness_text = wibox.widget.textbox()
    brightness_text:set_font(font)

    local brightness_icon = wibox.widget {
        {
            image = path_to_icon,
            resize = false,
            widget = wibox.widget.imagebox,
        },
        top = 3,
        widget = wibox.container.margin
    }

    brightness_widget = wibox.widget {
        brightness_icon,
        brightness_text,
        layout = wibox.layout.fixed.horizontal,
    }

    local update_widget = function(widget, stdout, _, _, _)
        local brightness_level = tonumber(string.format("%.0f", stdout))
        widget:set_text(" " .. brightness_level .. "%")
    end

    brightness_widget:connect_signal("button::press", function(_, _, _, button)
        if (button == 4) then
            spawn(inc_brightness_cmd, false)
        elseif (button == 5) then
            spawn(dec_brightness_cmd, false)
        end
    end)

    watch(get_brightness_cmd, timeout, update_widget, brightness_text)

    return brightness_widget
end

return setmetatable(brightness_widget, { __call = function(_, ...)
    return worker(...)
end })
