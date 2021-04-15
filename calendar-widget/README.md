# Calendar Widget

Calendar widget for Awesome WM - slightly improved version of the `wibox.widget.calendar`.

## Features

 - mouse support: scroll up - shows next month, scroll down - previous
 - themes:
  
    | Name | Screenshot |
    |---|---|
    | nord (default) | ![nord_theme](./nord.png) |
    | outrun | ![outrun_theme](./outrun.png) |
    | light | ![outrun_theme](./light.png) |
    | dark | ![outrun_theme](./dark.png) |
    | naughty (default) | from local theme |
  
 - setup widget placement
  
  top center - in case you clock is centered:

   ![calendar_top](./calendar_top.png)

  top right - for default awesome config:

  ![calendar_top_right](./calendar_top_right.png)

  bottom right - in case your wibar at the bottom:

  ![calendar_bottom_right](./calendar_bottom_right.png)


## How to use

This widget needs an 'anchor' - another widget which triggers visibility of the calendar. Default `mytextclock` is the perfect candidate!  
Just after mytextclock is instantiated, create the widget and add the mouse listener to it.

```lua
local calendar_widget = require("awesome-wm-widgets.calendar-widget.calendar")
-- ...
-- Create a textclock widget
mytextclock = wibox.widget.textclock()
-- default
local cw = calendar_widget()
-- or customized
local cw = calendar_widget({
    theme = 'outrun',
    placement = 'bottom_right',
    radius = 8,
})
mytextclock:connect_signal("button::press", 
    function(_, _, _, button)
        if button == 1 then cw.toggle() end
    end)
```
