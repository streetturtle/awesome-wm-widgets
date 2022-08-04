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

local prev_highlight = nil

local function highlight_item(item)
    if (not (prev_highlight == nil)) then
        prev_highlight.opacity = 0.7
    end
    item.opacity = 1
    prev_highlight = item

end

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

    -- Change item background on mouse hover
    row:connect_signal("mouse::leave", function(c) c:set_bg(beautiful.bg_normal) end)
    row:connect_signal("mouse::enter", function(c) c:set_bg(beautiful.bg_focus) end)

    -- Change cursor on mouse hover
    local old_cursor, old_wibox
    row:connect_signal("mouse::enter", function()
        local wb = mouse.current_wibox
        old_cursor, old_wibox = wb.cursor, wb
        wb.cursor = "hand1"
    end)
    row:connect_signal("mouse::leave", function()
        if old_wibox then
            old_wibox.cursor = old_cursor
            old_wibox = nil
        end
    end)

    -- Mouse click handler
    row:buttons(
        awful.util.table.join(
            awful.button({}, 1, function()
                popup.visible = not popup.visible
                awful.spawn.with_shell('echo -n "' .. name .. '" | xclip -selection clipboard')
                highlight_item(row)
            end),
            awful.button({}, 3, function()
                local index = 0
                for i, v in ipairs(menu_items) do
                    if (v == name) then
                        index = i
                        break
                    end
                end
                table.remove(menu_items, index)
                popup.widget:remove(index)
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


    local rows = { layout = wibox.layout.fixed.vertical }

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

    watch("xclip -selection clipboard -o -rmlastnl", 1,
        function(widget, stdout)
            local hasItem = false
            -- Remove trailing whitespace
            stdout = (stdout:gsub("^%s*(.-)%s*$", "%1"))

            for i, v in ipairs(menu_items) do
                if (v == stdout) then
                    hasItem = true
                    break
                end
            end

            if (not hasItem) then
                local row = build_item(popup, stdout)
                highlight_item(row)
                popup.widget:add(row)
            end

            if (#menu_items > 10) then
                table.remove(menu_items, 1)
                popup.widget:remove(1)
            end
        end)

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
