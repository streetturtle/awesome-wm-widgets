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

local function highlight_item(item, unactive_item_dim)
    if (not (prev_highlight == nil)) then
        prev_highlight.opacity = unactive_item_dim
    end
    item.opacity = 1
    prev_highlight = item

end

local function build_item(popup, name, max_show_length, margin, unactive_item_dim, font)
    table.insert(menu_items, name)

    local row = wibox.widget {
        {
            {
                text = (string.len(name) > max_show_length and string.sub(name, 0, max_show_length) .. "..." or name),
                widget = wibox.widget.textbox,
                font = font
            },
            margins = margin,
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
                highlight_item(row, unactive_item_dim)
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

local function build_popup(maximum_popup_width)
    local popup = awful.popup {
        ontop = true,
        visible = false,
        shape = function(cr, width, height)
            gears.shape.rounded_rect(cr, width, height, 4)
        end,
        border_width = 1,
        border_color = beautiful.bg_focus,
        maximum_width = maximum_popup_width,
        offset = { y = 5 },
        widget = {}
    }

    local rows = { layout = wibox.layout.fixed.vertical }

    -- Add rows to the popup
    popup:setup(rows)

    return popup
end

local function worker(user_args)
    local args = user_args or {}

    local font = args.font or "Play 12"
    local timeout = args.timeout or 1
    local margin = args.margin or 16
    local max_items = args.max_items or 10
    local max_show_length = args.max_show_length or 64
    local maximum_popup_width = args.maximum_popup_width or 400
    local widget_name = (args.widget_name or "Clip") .. " "
    local unactive_item_dim = args.unactive_item_dim or 0.7

    clipboard_widget = wibox.widget {
        widget = wibox.widget.textbox,
        text = widget_name
    }

    local popup = build_popup(maximum_popup_width)

    watch("xclip -selection clipboard -o -rmlastnl", timeout,
        function(widget, stdout)
            local hasItem = false
            -- Remove trailing whitespace
            stdout = (stdout:gsub("^%s*(.-)%s*$", "%1"))

            -- No empty items
            if (stdout == "") then
                return
            end

            for i, v in ipairs(menu_items) do
                if (v == stdout) then
                    hasItem = true
                    break
                end
            end

            if (not hasItem) then
                local row = build_item(popup, stdout, max_show_length, margin, unactive_item_dim, font)
                highlight_item(row, unactive_item_dim)
                popup.widget:add(row)
            end

            if (#menu_items > max_items) then
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
