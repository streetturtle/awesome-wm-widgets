# Volumebar widget

Almost the same as volume widget, but more minimalistic:

![screenshot](out.gif)

Supports 
 - scroll up - increase volume, 
 - scroll down - decrease volume, 
 - left click - mute/unmute.
 
 ## Installation
 
 Clone repo, include widget and use it in **rc.lua**:
 
 ```lua
local volumebar_widget = require("awesome-wm-widgets.volumebar-widget.volumebar")
...
s.mytasklist, -- Middle widget
	{ -- Right widgets
    	layout = wibox.layout.fixed.horizontal,
		...
		volumebar_widget,
		...      
 ```

## Troubleshooting

If the bar is not showing up, try to decrease top or bottom margin - widget uses hardcoded margins for vertical alignment, so if your wibox is too small then bar is simply hidden by the margins.
