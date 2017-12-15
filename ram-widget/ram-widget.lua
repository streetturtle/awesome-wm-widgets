local awful = require("awful")
local watch = require("awful.widget.watch")
local wibox = require("wibox")

local ramgraph_widget = wibox.widget {
    border_width = 0,
    colors = {
        '#74aeab', '#26403f'
    },
    display_labels = false,
    forced_width = 25,
    widget = wibox.widget.piechart
}

local total, used, free, shared, buff_cache, available

watch('bash -c "free | grep Mem"', 1,
    function(widget, stdout, stderr, exitreason, exitcode)
        total, used, free, shared, buff_cache, available = stdout:match('(%d+)%s*(%d+)%s*(%d+)%s*(%d+)%s*(%d+)%s*(%d+)')

        widget.data = {used, total-used}
    end,
    ramgraph_widget
)

local w = wibox {
    height = 200,
    width = 350,
    ontop = true,
    screen = mouse.screen,
    expand = true,
    bg = '#1e252c',
    max_widget_size = 500
}

w:setup {
    {
        border_width = 0,
        colors = {
            '#74aeab',
            '#6eaaa7',
            '#5ea19d',
            '#55918e',
            '#4b817e',
        },
        display_labels = false,
        forced_width = 25,
        id = 'pie',
        widget = wibox.widget.piechart
    },
    {
        text = 'Hello',
        widget = wibox.widget.textbox
    },
    id = 'popup',
    layout = wibox.layout.stack
}

local function getPercentage(value)
    return math.floor(value / total * 100 + 0.5) .. '%'
end

ramgraph_widget:buttons(
    awful.util.table.join(
        awful.button({}, 1, function()
            awful.placement.top_right(w, { margins = {top = 25, right = 10}})
            w.popup.pie.data_list = {
                {'used ' .. getPercentage(used), used},
                {'free ' .. getPercentage(free), free},
--                {'shared ' .. getPercentage(shared), shared},
                {'buff_cache ' .. getPercentage(buff_cache), buff_cache},
--                {'available ' .. getPercentage(available), available}
            }
            w.popup.pie.display_labels = true
            w.visible = true
        end),
        awful.button({}, 3, function()
            w.visible = false;
        end)
    )
)

return ramgraph_widget
