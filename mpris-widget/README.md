# MPRIS Widget (In progress)

Music Player Info widget cy @mgabs

# Prerequisite

Install `playerctl` (mpris implementation), should be available in repo, e.g for Ubuntu:

```bash
sudo apt-get install playerctl
```

## Installation

To use this widget clone repo under **~/.config/awesome/** and then add it in **rc.lua**:

```lua
local mpris_widget = require("awesome-wm-widgets.mpris-widget")
...
s.mytasklist, -- Middle widget
	{ -- Right widgets
    layout = wibox.layout.fixed.horizontal,
		...
    mpris_widget,
		...
```
