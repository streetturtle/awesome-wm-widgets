# Net Speed Widget

The widget and readme is in progress

## Installation

Please refer to the [installation](https://github.com/streetturtle/awesome-wm-widgets#installation) section of the repo.

Clone repo, include widget and use it in **rc.lua**:

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
