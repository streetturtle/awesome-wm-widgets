-------------------------------------------------
-- ToDo Widget for Awesome Window Manager
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/todo-widget

-- @author Pavel Makhov
-- @copyright 2020 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local json = require("json")
local spawn = require("awful.spawn")
local naughty = require("naughty")
local gears = require("gears")
local beautiful = require("beautiful")
local gfs = require("gears.filesystem")
local gs = require("gears.string")

local HOME_DIR = os.getenv("HOME")

local STORAGE = HOME_DIR .. '/.cache/awmw/todo-widget/todos.json'
local GET_TODO_ITEMS = 'bash -c "cat ' .. STORAGE .. '"'

local rows  = { layout = wibox.layout.fixed.vertical }

local todo_widget = {}

todo_widget.widget = wibox.widget {
    {
        {
            id = "icon",
            widget = wibox.widget.imagebox
        },
        id = "margin",
        margins = 4,
        layout = wibox.container.margin
    },
    {
        id = "txt",
        widget = wibox.widget.textbox
    },
    layout = wibox.layout.fixed.horizontal,
    set_text = function(self, new_value)
        self.txt.text = new_value
    end,
    set_icon = function(self, new_value)
        self.margin.icon.image = new_value
    end
}

function todo_widget:update_counter(todos)
    local todo_count = 0
    for _,p in ipairs(todos) do
        if not p.status then
            todo_count = todo_count + 1
        end
    end

    todo_widget.widget:set_text(todo_count)
end

local popup = awful.popup{
    bg = beautiful.bg_normal,
    ontop = true,
    visible = false,
    shape = gears.shape.rounded_rect,
    border_width = 1,
    border_color = beautiful.bg_focus,
    maximum_width = 400,
    offset = { y = 5 },
    widget = {}
}

local add_button = wibox.widget {
    {
        {
            image = '/usr/share/icons/Arc/actions/symbolic/list-add-symbolic.svg',
            resize = false,
            widget = wibox.widget.imagebox
        },
        top = 11,
        left = 8,
        right = 8,
        layout = wibox.container.margin
    },
    shape = function(cr, width, height)
        gears.shape.circle(cr, width, height, 12)
    end,
    widget = wibox.container.background
}

add_button:connect_signal("button::press", function(c)
    local pr = awful.widget.prompt()

    table.insert(rows, wibox.widget {
        {
            {
                pr.widget,
                spacing = 8,
                layout = wibox.layout.align.horizontal
            },
            margins = 8,
            layout = wibox.container.margin
        },
        bg = beautiful.bg_normal,
        widget = wibox.container.background
    })
    awful.prompt.run{
        prompt = "<b>New item</b>: ",
        bg = beautiful.bg_normal,
        bg_cursor = beautiful.fg_urgent,
        textbox = pr.widget,
        exe_callback = function(input_text)
            if not input_text or #input_text == 0 then return end
            spawn.easy_async(GET_TODO_ITEMS, function(stdout)
                local res = json.decode(stdout)
                table.insert(res.todo_items, {todo_item = input_text, status = false})
                spawn.easy_async_with_shell("echo '" .. json.encode(res) .. "' > " .. STORAGE, function()
                    spawn.easy_async(GET_TODO_ITEMS, function(stdout) update_widget(stdout) end)
                end)
            end)
        end
    }
    popup:setup(rows)
end)
add_button:connect_signal("mouse::enter", function(c) c:set_bg(beautiful.bg_focus) end)
add_button:connect_signal("mouse::leave", function(c) c:set_bg(beautiful.bg_normal) end)

local function worker(args)

    local args = args or {}

    local icon = args.icon or '/usr/share/icons/Arc/status/symbolic/checkbox-checked-symbolic.svg'

    todo_widget.widget:set_icon(icon)

    function update_widget(stdout)
        local result = json.decode(stdout)
        if result == nil or result == '' then result = {} end
        todo_widget:update_counter(result.todo_items)

        for i = 0, #rows do rows[i]=nil end

        local first_row = wibox.widget {
            {
                {widget = wibox.widget.textbox},
                {
                    markup = '<span size="large" font_weight="bold" color="#ffffff">ToDo</span>',
                    align = 'center',
                    forced_width = 350, -- for horizontal alignment
                    forced_height = 40,
                    widget = wibox.widget.textbox
                },
                add_button,
                spacing = 8,
                layout = wibox.layout.fixed.horizontal
            },
            bg = beautiful.bg_normal,
            widget = wibox.container.background
        }

        table.insert(rows, first_row)


        for i, todo_item in ipairs(result.todo_items) do

            local checkbox = wibox.widget {
                checked       = todo_item.status,
                color         = beautiful.bg_normal,
                paddings      = 2,
                shape         = gears.shape.circle,
                forced_width = 20,
                forced_height = 20,
                check_color = beautiful.fg_urgent,
                widget        = wibox.widget.checkbox
            }

            checkbox:connect_signal("button::press", function(c)
                c:set_checked(not c.checked)
                todo_item.status = not todo_item.status
                result.todo_items[i] = todo_item
                spawn.easy_async_with_shell("echo '" .. json.encode(result) .. "' > " .. STORAGE)
                todo_widget:update_counter(result.todo_items)
            end)

            local trash_button = wibox.widget {
                {
                    {    image = '/usr/share/icons/Arc/actions/symbolic/window-close-symbolic.svg',
                        resize = false,
                        widget = wibox.widget.imagebox
                    },
                    margins = 5,
                    layout = wibox.container.margin
                },
                border_width = 1,
                shape = function(cr, width, height)
                    gears.shape.circle(cr, width, height, 10)
                end,
                widget = wibox.container.background
            }

            trash_button:connect_signal("button::press", function(c)
                table.remove(result.todo_items, i)
                spawn.easy_async_with_shell("printf '" .. json.encode(result) .. "' > /home/pmakhov/.cache/awmw/todo-widget/todos.json")
                spawn.easy_async(GET_TODO_ITEMS, function(stdout) update_widget(stdout) end)
            end)

            local row = wibox.widget {
                {
                    {
                        {
                            
                            checkbox,
                            valign = 'center',
                            layout = wibox.container.place,
                        },
                        {
                            {
                                text = todo_item.todo_item,
                                align = 'left',
                                widget = wibox.widget.textbox
                            },
                            left = 10,
                            layout = wibox.container.margin
                        },
                        {
                            trash_button,
                            valign = 'center',
                            layout = wibox.container.place,
                        },
                        spacing = 8,
                        layout = wibox.layout.align.horizontal
                    },
                    margins = 8,
                    layout = wibox.container.margin
                },
                bg = beautiful.bg_normal,
                widget = wibox.container.background
            }

            row:connect_signal("mouse::enter", function(c) c:set_bg(beautiful.bg_focus) end)
            row:connect_signal("mouse::leave", function(c) c:set_bg(beautiful.bg_normal) end)

            table.insert(rows, row)
        end

        popup:setup(rows)
    end

    todo_widget.widget:buttons(
            awful.util.table.join(
                    awful.button({}, 1, function()
                        if popup.visible then
                            popup.visible = not popup.visible
                        else
                            popup:move_next_to(mouse.current_widget_geometry)
                        end
                    end)
            )
    )

    spawn.easy_async(GET_TODO_ITEMS, function(stdout) update_widget(stdout) end)

    return todo_widget.widget
end

if not gfs.file_readable(STORAGE) then
    spawn.easy_async(string.format([[bash -c "dirname %s | xargs mkdir -p && echo '{\"todo_items\":{}}' > %s"]], STORAGE, STORAGE))
end

return setmetatable(todo_widget, { __call = function(_, ...) return worker(...) end })
