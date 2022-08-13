-------------------------------------------------
-- Clipboard Widget for Awesome Window Manager
-- Simple clipboard managment using xclip
-------------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gears = require("gears")
local watch = require("awful.widget.watch")

local HOME = os.getenv("HOME")
local WIDGET_DIR = HOME .. '/.config/awesome/clipboard-widget/clipboard-widget/'

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

local function copy_to_clipboard(text)
    awful.spawn.with_shell([[echo -n "]] .. text .. [[" | xclip -selection clipboard]])
end

-- Save item to storage
local function save_items()
    local content = ""
    for i, v in ipairs(menu_items) do
        content = content .. v .. "~~"
    end
    awful.spawn.with_shell("echo -nE '" .. content .. "' > " .. WIDGET_DIR .. "storage.txt")
end

local function build_item(popup, name, max_show_length, margin, unactive_item_dim, font)
    table.insert(menu_items, name)

    local row = wibox.widget {
        id = "first",
        {
            id = "second",
            {
                id = "third",
                -- Show only a part of text
                text = (string.len(name) > max_show_length and string.sub(name, 0, max_show_length) .. "..." or name),
                actual_text = name,
                widget = wibox.widget.textbox,
                font = font
            },
            margins = margin,
            widget = wibox.container.margin
        },
        bg = beautiful.bg_normal,
        widget = wibox.container.background,
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

                copy_to_clipboard(name)
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

                -- If the item is currently in clipboard clear it
                if (row.opacity == 1) then
                    copy_to_clipboard("")
                    prev_highlight.second.third.text = ""
                    prev_highlight.second.third.actual_text = ""
                end

                table.remove(menu_items, index)
                popup.widget:remove(index)
                save_items()
            end)
        )
    )

    save_items()
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

    local font = args.font or beautiful.font
    local timeout = args.timeout or 0.1
    local margin = args.margin or 16
    local max_items = args.max_items or 10
    local max_show_length = args.max_show_length or 64
    local maximum_popup_width = args.maximum_popup_width or 400
    local widget_name = (args.widget_name or "Clip") .. " "
    local unactive_item_dim = args.unactive_item_dim or 0.7
    local max_peek_length = args.max_show_length or 32

    clipboard_widget.widget = wibox.widget {
        widget = wibox.widget.textbox,
        text = widget_name,
    }

    local popup = build_popup(maximum_popup_width)

    -- Load items from storage
    awful.spawn.easy_async_with_shell('cat ' .. WIDGET_DIR .. 'storage.txt', function(stdout)
        local sep = "~~"
        local t = {}
        for str in string.gmatch(stdout, "([^" .. sep .. "]+)") do
            -- Remove trailing whitespace
            str = (str:gsub("^%s*(.-)%s*$", "%1"))

            if (not (str == "")) then
                table.insert(t, str)
            end
        end

        for i, v in ipairs(t) do
            local row = build_item(popup, v, max_show_length, margin, unactive_item_dim, font)
            row.opacity = unactive_item_dim
            popup.widget:add(row)
        end

    end)


    local content_shown = false

    watch("xclip -selection clipboard -o -rmlastnl", timeout,
        function(widget, stdout)
            local hasItem = false
            -- Remove trailing whitespace
            stdout = (stdout:gsub("^%s*(.-)%s*$", "%1"))
            -- Starts to freak out and cant interpret the strings whithout it
            stdout = string.gsub(stdout, '"', "'")

            -- No empty items
            if (stdout == "") then
                clipboard_widget.widget.text = widget_name
                -- If theres an item highlighted but the clipboard is empty copy the highlited item to clipboard
                if (not (prev_highlight == nil)) then
                    copy_to_clipboard(prev_highlight.second.third.actual_text)
                end
                return
            end

            if (content_shown) then
                local text = (string.len(stdout) > max_peek_length and string.sub(stdout, 0, max_peek_length) .. "..." or stdout)
                clipboard_widget.widget.text = text .. " ";
            end

            for i, v in ipairs(menu_items) do
                if (v == stdout) then
                    highlight_item(popup.widget.children[i], unactive_item_dim)
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

    function clipboard_widget:show_content()
        if (content_shown) then
            content_shown = false
            clipboard_widget.widget.text = widget_name
        else
            content_shown = true
        end
    end

    function clipboard_widget:next_item()
        if (#menu_items > 0) then
            local index = 0
            for i, v in ipairs(menu_items) do
                if (v == prev_highlight.second.third.actual_text) then
                    index = i
                    break
                end
            end

            index = index + 1
            if (index > #menu_items) then
                index = 1
            end

            copy_to_clipboard(popup.widget.children[index].second.third.actual_text)
            highlight_item(popup.widget.children[index], unactive_item_dim)
        end
    end

    function clipboard_widget:previous_item()
        if (#menu_items > 0) then
            local index = 0
            for i, v in ipairs(menu_items) do
                if (v == prev_highlight.second.third.actual_text) then
                    index = i
                    break
                end
            end

            index = index - 1
            if (index < 1) then
                index = #menu_items
            end

            copy_to_clipboard(popup.widget.children[index].second.third.actual_text)
            highlight_item(popup.widget.children[index], unactive_item_dim)
        end
    end

    function clipboard_widget:delete_item()
        if (#menu_items > 0) then
            local index = 0
            for i, v in ipairs(menu_items) do
                if (v == prev_highlight.second.third.actual_text) then
                    index = i
                    break
                end
            end

            -- If the item is currently in clipboard clear it
            if (prev_highlight.opacity == 1) then
                copy_to_clipboard("")
                prev_highlight.second.third.text = ""
                prev_highlight.second.third.actual_text = ""
            end

            table.remove(menu_items, index)
            popup.widget:remove(index)
            save_items()

            if (index > #menu_items) then
                index = #menu_items
            end

            if (#menu_items > 0) then
                copy_to_clipboard(popup.widget.children[index].second.third.actual_text)
                highlight_item(popup.widget.children[index], unactive_item_dim)
            end
        end
    end

    -- Mouse click handler
    clipboard_widget.widget:buttons(
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
