local awful = require("awful")
local watch = require("awful.widget.watch")
local wibox = require("wibox")

local cpugraph_widget = wibox.widget {
    max_value = 100,
    color = '#74aeab',
    background_color = "#1e252c",
    forced_width = 50,
    step_width = 2,
    step_spacing = 1,
    widget = wibox.widget.graph
}

cpu_widget = wibox.container.margin(wibox.container.mirror(cpugraph_widget, { horizontal = true }), 0, 0, 0, 2)

local total_prev = 0
local idle_prev = 0

watch("cat /proc/stat | grep '^cpu '", 1,
    function(widget, stdout, stderr, exitreason, exitcode)
        local user, nice, system, idle, iowait, irq, softirq, steal, guest, guest_nice =
        stdout:match('(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s')

        local total = user + nice + system + idle + iowait + irq + softirq + steal

        local diff_idle = idle - idle_prev
        local diff_total = total - total_prev
        local diff_usage = (1000 * (diff_total - diff_idle) / diff_total + 5) / 10

        if diff_usage > 80 then
            widget:set_color('#ff4136')
        else
            widget:set_color('#74aeab')
        end

        widget:add_value(diff_usage)

        total_prev = total
        idle_prev = idle
    end,
    cpugraph_widget
)

cpugraph_widget:buttons(
    awful.util.table.join(
        awful.button({}, 1, function() awful.spawn.with_shell("echo left | xsel --clipboard")  end),
        awful.button({}, 3, function() awful.spawn.with_shell("echo right | xsel --clipboard") end)
    )
)
