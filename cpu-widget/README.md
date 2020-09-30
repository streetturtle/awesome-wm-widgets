# CPU widget

[![GitHub issues by-label](https://img.shields.io/github/issues-raw/streetturtle/awesome-wm-widgets/cpu)](https://github.com/streetturtle/awesome-wm-widgets/labels/cpu)

This widget shows the average CPU load among all cores of the machine:

![screenshot](./cpu.gif)

## How it works

To measure the load I took Paul Colby's bash [script](http://colby.id.au/calculating-cpu-usage-from-proc-stat/) and rewrote it in Lua, which was quite simple.
So awesome simply reads the first line of /proc/stat:

```bash
$ cat /proc/stat | grep '^cpu '
cpu  197294 718 50102 2002182 3844 0 2724 0 0 0
```

and calculates the percentage.

## Customization

It is possible to customize widget by providing a table with all or some of the following config parameters:

| Name | Default | Description |
|---|---|---|
| `width` | 50 | Width of the widget |
| `step_width` | 2 | Width of the step |
| `step_spacing` | 1 | Space size between steps |
| `color` | `beautiful.fg_normal` | Color of the graph |
| `enable_kill_button` | `false` | Show button which kills the process |
| `process_info_max_length` | `-1` | Truncate the process information. Some processes may have a very long list of parameters which won't fit in the screen, this options allows to truncate it to the given length. |
| `timeout` | 1 | How often in seconds the widget refreshes |

### Example

```lua
cpu_widget({
    width = 70,
    step_width = 2,
    step_spacing = 0,
    color = '#434c5e'
})
```

The config above results in the following widget:

![custom](./custom.png)

## Installation

Clone/download repo and use widget in **rc.lua**:

```lua
local cpu_widget = require("awesome-wm-widgets.cpu-widget.cpu-widget")
...
s.mytasklist, -- Middle widget
	{ -- Right widgets
    	layout = wibox.layout.fixed.horizontal,
		...
		-- default
		cpu_widget(),
		-- or custom
		cpu_widget({
            width = 70,
            step_width = 2,
            step_spacing = 0,
            color = '#434c5e'
        })
		...
```
