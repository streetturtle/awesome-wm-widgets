-------------------------------------------------
-- Clipboard Widget for Awesome Window Manager
-- Simple clipboard managment using xclip
-------------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gears = require("gears")
local watch = require("awful.widget.watch")

--- Widget to add to the wibar
local clipboard_widget = {}
local menu_items = {}

local function worker()
    clipboard_widget = wibox.widget {
        widget = wibox.widget.textbox,
        text = "Clip "
    }

    return clipboard_widget
end

return setmetatable(clipboard_widget, { __call = function(_, ...)
    return worker(...)
end })
