---
layout: page
---
# Net Speed Widget

The widget and README are in progress.

## Installation

Clone/download repo and use widget in **rc.lua**:

```lua
local net_speed_widget = require("awesome-wm-widgets.net-speed-widget.net-speed")
...
s.mytasklist, -- Middle widget
	{ -- Right widgets
    	layout = wibox.layout.fixed.horizontal,
		...
		net_speed_widget(),
    		...
	}
	...
```
