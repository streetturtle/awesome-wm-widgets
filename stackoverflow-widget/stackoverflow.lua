-------------------------------------------------
-- Stackoverflow Widget for Awesome Window Manager
-- Shows new questions by a given tag
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/stackoverflow-widget

-- @author Pavel Makhov
-- @copyright 2019 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local watch = require("awful.widget.watch")
local json = require("json")
local spawn = require("awful.spawn")
local gears = require("gears")
local beautiful = require("beautiful")

local HOME_DIR = os.getenv("HOME")

local GET_QUESTIONS_CMD = [[bash -c "curl --compressed -s -X GET]]
    .. [[ 'http://api.stackexchange.com/2.2/questions/no-answers]]
    .. [[?page=1&pagesize=%s&order=desc&sort=activity&tagged=%s&site=stackoverflow'"]]

local stackoverflow_widget = {}

local function worker(user_args)

    local args = user_args or {}

    local icon = args.icon or HOME_DIR .. '/.config/awesome/awesome-wm-widgets/stackoverflow-widget/so-icon.svg'
    local limit = args.limit or 5
    local tagged = args.tagged or 'awesome-wm'
    local timeout = args.timeout or 300

    local rows = {
        { widget = wibox.widget.textbox },
        layout = wibox.layout.fixed.vertical,
    }

    local popup = awful.popup{
        ontop = true,
        visible = false,
        shape = gears.shape.rounded_rect,
        border_width = 1,
        border_color = beautiful.bg_focus,
        maximum_width = 400,
        preferred_positions = 'top',
        offset = { y = 5 },
        widget = {}
    }

    stackoverflow_widget = wibox.widget {
        {
            image = icon,
            widget = wibox.widget.imagebox
        },
        {
            id = "txt",
            widget = wibox.widget.textbox
        },
        layout = wibox.layout.fixed.horizontal,
        set_text = function(self, new_value)
            self.txt.text = new_value
        end,
    }

    local update_widget = function(_, stdout, _, _, _)

        local result = json.decode(stdout)

        for i = 0, #rows do rows[i]=nil end
        for _, item in ipairs(result.items) do
            local tags = ''
            for i = 1, #item.tags do tags = tags .. item.tags[i] .. ' ' end
            local row = wibox.widget {
                {
                    {
                        {
                            text = item.title,
                            widget = wibox.widget.textbox
                        },
                        {
                            text = tags,
                            align = 'right',
                            widget = wibox.widget.textbox
                        },
                        layout = wibox.layout.align.vertical
                    },
                    margins = 8,
                    layout = wibox.container.margin
                },
                widget = wibox.container.background
            }

            row:connect_signal("button::release", function()
                spawn.with_shell("xdg-open " .. item.link)
                popup.visible = false
            end)

            row:connect_signal("mouse::enter", function(c) c:set_bg(beautiful.bg_focus) end)
            row:connect_signal("mouse::leave", function(c) c:set_bg(beautiful.bg_normal) end)

            table.insert(rows, row)
        end

        popup:setup(rows)
    end

    stackoverflow_widget:buttons(
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
    watch(string.format(GET_QUESTIONS_CMD, limit, tagged),  timeout, update_widget, stackoverflow_widget)
    return stackoverflow_widget
end

return setmetatable(stackoverflow_widget, { __call = function(_, ...) return worker(...) end })
