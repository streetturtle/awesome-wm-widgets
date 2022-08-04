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

local function build_popup()
    local popup = awful.popup {
        ontop = true,
        visible = false,
        shape = function(cr, width, height)
            gears.shape.rounded_rect(cr, width, height, 4)
        end,
        border_width = 1,
        border_color = beautiful.bg_focus,
        maximum_width = 400,
        offset = { y = 5 },
        widget = {}
    }

    local row = wibox.widget {
        {
            {
                {
                    text = "Hello",
                    widget = wibox.widget.textbox
                },
                spacing = 16,
                layout = wibox.layout.fixed.horizontal
            },
            margins = 16,
            widget = wibox.container.margin
        },
        bg = beautiful.bg_normal,
        widget = wibox.container.background
    }

    local rows = { row, layout = wibox.layout.fixed.vertical }

    -- Add rows to the popup
    popup:setup(rows)

    return popup
end

local function worker()
    clipboard_widget = wibox.widget {
        widget = wibox.widget.textbox,
        text = "Clip "
    }

    local popup = build_popup()
    popup.visible = true

    return clipboard_widget
end

return setmetatable(clipboard_widget, { __call = function(_, ...)
    return worker(...)
end })
