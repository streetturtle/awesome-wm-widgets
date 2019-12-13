# Calendar Widget

Calendar widget for Awesome WM - slightly improved version of the `wibox.widget.calendar`. Also supports mouse scroll up/down in order ot switch month - scroll up - shows next month, scroll down - previous.

Top center placement:

![calendar_top](./calendar_top.png)

Top right placement:

![calendar_top_right](./calendar_top_right.png)

The placement is setup in theme.lua by `calendar_placement` variable, currently supported `top` (default), `top_right`, `bottom_right`. 

# How to use

This widget needs an 'anchor' - another widget which triggers visibility of the calendar. Default `mytextclock` is the perfect candidate!

```lua
local calendar_widget = require("awesome-wm-widgets.calendar-widget.calendar")
-- ...
-- Create a textclock widget
mytextclock = wibox.widget.textclock()
mytextclock:connect_signal("button::press",
    function(_, _, _, button)
        if button == 1 then calendar_widget.toggle() end
    end)
```