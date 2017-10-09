# Volumearc widget

Almost the same as [volumebar widget](https://github.com/streetturtle/awesome-wm-widgets/tree/master/volumebar-widget), but using arcchart:

![screenshot](out.gif)

Supports:
 - scroll up - increase volume,
 - scroll down - decrease volume,
 - left click - mute/unmute.

## Installation

Clone repo, include widget and use it in **rc.lua**:

```lua
require("volumearc")
...
s.mytasklist, -- Middle widget
	{ -- Right widgets
    	layout = wibox.layout.fixed.horizontal,
		...
		volumearc_widget,
		...
```
