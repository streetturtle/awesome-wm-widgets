# MPD Widget

Music Player Daemon widget by @raphaelfournier.

# Prerequisite

Install `mpd` (Music Player Daemon itself) and `mpc` (Music Player Client - program for controlling mpd), both should be available in repo, e.g for Ubuntu:

```bash
sudo apt-get install mpd mpc
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
    mpdarc_widget,
		...
```
