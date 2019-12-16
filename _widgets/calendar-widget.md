---
layout: page
---
# Calendar Widget

Calendar widget for Awesome WM - slightly improved version of the `wibox.widget.calendar`.

## Features

 - mouse support: scroll up - shows next month, scroll down - previous
 - themes:
  
  nord (default):

  ![nord_theme](../awesome-wm-widgets/assets/img/screenshots/calendar-widget/nord.png)

  outrun:

  ![outrun_theme](../awesome-wm-widgets/assets/img/screenshots/calendar-widget/outrun.png)

 - setup widget placement
  
  top center - in case you clock is centered:

   ![calendar_top](../awesome-wm-widgets/assets/img/screenshots/calendar-widget/calendar_top.png)

  top right - for default awesome config:

  ![calendar_top_right](../awesome-wm-widgets/assets/img/screenshots/calendar-widget/calendar_top_right.png)

  bottom right - in case your wibar at the bottom:

  ![calendar_bottom_right](../awesome-wm-widgets/assets/img/screenshots/calendar-widget/calendar_bottom_right.png)


## How to use

This widget needs an 'anchor' - another widget which triggers visibility of the calendar. Default `mytextclock` is the perfect candidate!

```lua
local calendar_widget = require("awesome-wm-widgets.calendar-widget.calendar")
-- ...
-- {{{ Wibar
-- Create a textclock widget
mytextclock = wibox.widget.textclock()
-- default
cw = calendar_widget()
-- or customized
cw = calendar_widget({
    theme = 'outrun',
    placement = 'bottom_right'
})
mytextclock:connect_signal("button::press", 
    function(_, _, _, button)
        if button == 1 then cw.toggle() end
    end)
```
