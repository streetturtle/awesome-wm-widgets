-------------------------------------------------
-- CPU Widget for Awesome Window Manager
-- Shows the current CPU utilization
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/cpu-widget

-- @author Pavel Makhov
-- @copyright 2019 Pavel Makhov
-------------------------------------------------

local watch = require("awful.widget.watch")
local wibox = require("wibox")

local cpugraph_widget = wibox.widget {
    max_value = 100,
    background_color = "#00000000",
    forced_width = 50,
    step_width = 2,
    step_spacing = 1,
    widget = wibox.widget.graph,
    color = "linear:0,0:0,22:0,#FF0000:0.3,#FFFF00:0.5,#74aeab"
}

--- By default graph widget goes from left to right, so we mirror it and push up a bit
local cpu_widget = wibox.container.margin(wibox.container.mirror(cpugraph_widget, { horizontal = true }), 0, 0, 0, 2)

local total_prev = 0
local idle_prev = 0

watch([[bash -c "cat /proc/stat | grep '^cpu '"]], 1,
    function(widget, stdout)
        local user, nice, system, idle, iowait, irq, softirq, steal, guest, guest_nice =
        stdout:match('(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s')

        local total = user + nice + system + idle + iowait + irq + softirq + steal

        local diff_idle = idle - idle_prev
        local diff_total = total - total_prev
        local diff_usage = (1000 * (diff_total - diff_idle) / diff_total + 5) / 10

        widget:add_value(diff_usage)

        total_prev = total
        idle_prev = idle
    end,
    cpugraph_widget
)

return cpu_widget
