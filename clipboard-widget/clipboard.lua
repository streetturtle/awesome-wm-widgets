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

local function build_item(popup, name)
    table.insert(menu_items, name)

    local row = wibox.widget {
        {
            {
                text = (string.len(name) > 64 and string.sub(name, 0, 64) .. "..." or name),
                widget = wibox.widget.textbox
            },
            margins = 16,
            widget = wibox.container.margin
        },
        bg = beautiful.bg_normal,
        widget = wibox.container.background
    }

    -- Mouse click handler
    row:buttons(
        awful.util.table.join(
            awful.button({}, 1, function()
                popup.visible = not popup.visible
                awful.spawn.with_shell('echo -n "' .. name .. '" | xclip -selection clipboard')
            end)
        )
    )

    return row
end

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

    local row = build_item(popup, "Hello")
    local row2 = build_item(popup, "Hello2")

    local rows = { row, row2, layout = wibox.layout.fixed.vertical }

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

    -- Mouse click handler
    clipboard_widget:buttons(
        awful.util.table.join(
            awful.button({}, 1, function()
                if popup.visible then
                    popup.visible = not popup.visible
                else
                    popup:move_next_to(mouse.current_widget_geometry)
                end
            end))
    )

    return clipboard_widget
end

return setmetatable(clipboard_widget, { __call = function(_, ...)
    return worker(...)
end })
