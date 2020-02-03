-------------------------------------------------
-- CPU Widget for Awesome Window Manager
-- Shows the current CPU utilization
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/cpu-widget

-- @author Pavel Makhov
-- @copyright 2020 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local watch = require("awful.widget.watch")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gears = require("gears")

local widget = {}

local function worker(args)

    local args = args or {}

    local width = args.width or 50
    local step_width = args.step_width or 2
    local step_spacing = args.step_spacing or 1
    local color= args.color or beautiful.fg_normal

    local cpugraph_widget = wibox.widget {
        max_value = 100,
        background_color = "#00000000",
        forced_width = width,
        step_width = step_width,
        step_spacing = step_spacing,
        widget = wibox.widget.graph,
        color = "linear:0,0:0,20:0,#FF0000:0.3,#FFFF00:0.6," .. color
    }

    local rows = {
        { widget = wibox.widget.textbox },
        spacing = 4,
        layout = wibox.layout.fixed.vertical,

    }

    local popup = awful.popup{
        ontop = true,
        visible = false,
        shape = gears.shape.rounded_rect,
        border_width = 1,
        border_color = beautiful.bg_normal,
        maximum_width = 300,
        offset = { y = 5 },
        widget = {}
    }

    cpugraph_widget:buttons(
            awful.util.table.join(
                    awful.button({}, 1, function()
                        if popup.visible then
                            --rows = nil
                            popup.visible = not popup.visible
                        else
                            --init_popup()
                            popup:move_next_to(mouse.current_widget_geometry)
                        end
                    end)
            )
    )

    --- By default graph widget goes from left to right, so we mirror it and push up a bit
    local cpu_widget = wibox.container.margin(wibox.container.mirror(cpugraph_widget, { horizontal = true }), 0, 0, 0, 2)

    local cpus = {}
    watch([[bash -c "cat /proc/stat | grep '^cpu.'"]], 1,
            function(widget, stdout)
                local i = 1
                for cur in stdout:gmatch("[^\r\n]+") do
                    if cpus[i] == nil then cpus[i] = {} end

                    local name, user, nice, system, idle, iowait, irq, softirq, steal, guest, guest_nice =
                        cur:match('(%w+)%s+(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)')

                    local total = user + nice + system + idle + iowait + irq + softirq + steal

                    local diff_idle = idle - tonumber(cpus[i]['idle_prev'] == nil and 0 or cpus[i]['idle_prev'])
                    local diff_total = total - tonumber(cpus[i]['total_prev'] == nil and 0 or cpus[i]['total_prev'])
                    local diff_usage = (1000 * (diff_total - diff_idle) / diff_total + 5) / 10

                    cpus[i]['total_prev'] = total
                    cpus[i]['idle_prev'] = idle

                    if i == 1 then
                        widget:add_value(diff_usage)
                    end

                    local row = wibox.widget
                    {
                        {
                            text = name,
                            forced_width = 40,
                            widget = wibox.widget.textbox
                        },
                        {
                            text = string.format('%i%%', diff_usage),
                            forced_width = 40,
                            widget = wibox.widget.textbox
                        },
                        {
                            max_value = 100,
                            value = diff_usage,
                            forced_height = 20,
                            forced_width = 150,
                            paddings = 1,
                            margins = 4,
                            border_width = 1,
                            border_color = beautiful.bg_focus,
                            background_color = beautiful.bg_normal,
                            bar_border_width = 1,
                            bar_border_color = beautiful.bg_focus,
                            color = beautiful.bg_focus,
                            widget = wibox.widget.progressbar,

                        },
                        layout = wibox.layout.align.horizontal
                    }

                    rows[i] = row

                    i = i + 1
                end
                popup:setup {
                    {
                        rows,
                        layout = wibox.layout.align.vertical,
                    },
                    margins = 8,
                    widget = wibox.container.margin
                }
            end,
            cpugraph_widget
    )

    return cpu_widget
end

return setmetatable(widget, { __call = function(_, ...)
    return worker(...)
end })
