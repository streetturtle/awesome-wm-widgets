# APT widget

Widget which shows a list of APT packages to be updated:

![screenshot](./screenshots/screenshot.gif)

Features:
 - scrollable list !!! (thanks to this [post](https://www.reddit.com/r/awesomewm/comments/isx89x/scrolling_a_layout_fixed_flexed_layout_widget/) of reddit)
 - update single package
 - update multiple packages

## Installation

Clone the repo under ~/.config/awesome/ folder, then in rc.lua add the following:

```lua
local apt_widget = require("awesome-wm-widgets.apt-widget.apt-widget")

...
s.mytasklist, -- Middle widget
	{ -- Right widgets
    	layout = wibox.layout.fixed.horizontal,
		...
		apt_widget(),
		...
```

