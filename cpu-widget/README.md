# CPU widget

This widget shows the average CPU load among all cores of the machine:

![screenshot](out.gif)

When the load is more than 80% the graph becomes red. You can easily customize the widget by changing colors, step width, step spacing, width and interval.

## How it works

To measure the load I took Paul Colby's bash [script](http://colby.id.au/calculating-cpu-usage-from-proc-stat/) and rewrote it in Lua, which was quite simple.
So awesome simply reads the first line of /proc/stat:

```bash
$ cat /proc/stat | grep '^cpu '
cpu  197294 718 50102 2002182 3844 0 2724 0 0 0
```

and calculates the percentage.

## Installation

Clone/download repo and use widget in **rc.lua**:

```lua
require("awesome-wm-widgets.cpu-widget.cpu-widget")
...
s.mytasklist, -- Middle widget
	{ -- Right widgets
    	layout = wibox.layout.fixed.horizontal,
		...
		cpu_widget,
		...
```
