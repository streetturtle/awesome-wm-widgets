# MPRIS Widget

Music Player Daemon control widget by @mgabs.

# Prerequisite

Install `playerctl` - program for controlling mpris), both should be available in repo, e.g for Ubuntu:

```bash
sudo apt-get install playerctl
```

## Installation

To use this widget clone repo under **~/.config/awesome/** and then add it in **rc.lua**:

```lua
local mpdarc_widget = require("awesome-wm-widgets.mpdarc-widget.mpdarc")
...
s.mytasklist, -- Middle widget
	{ -- Right widgets
    layout = wibox.layout.fixed.horizontal,
		...
    mpdarc_widget(),
		...
```

## Options

The widgets takes button as boolean argument to enable or disable next & previous buttons
