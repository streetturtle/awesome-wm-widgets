local awful = require("awful")
local wibox = require("wibox")
local watch = require("awful.widget.watch")

local NETWORK_DEVICE = "/home/pmakhov/.config/awesome/awesome-wm-widgets/network-widget/networkio.sh"

net_widget = wibox.widget {
    font = "Play 9",
    widget = wibox.widget.textbox
}

local rspeed_prev = 0;
local tspeed_prev = 0;

watch(NETWORK_DEVICE, 1,
    function(widget, stdout, _, _, _)
        local r, t = string.match(stdout, '(%d+);(%d+)')

        local rspeed = r - rspeed_prev
        local tspeed = t - tspeed_prev

        rspeed_prev = r
        tspeed_prev = t

        widget:set_text(rspeed)
    end,
    net_widget)
