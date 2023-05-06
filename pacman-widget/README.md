# Pacman widget for AwesomeWM

This widget displays the number of upgradable Pacman packages. Clicking the icon reveals a scrollable list of available upgrades. A full system upgrade can be performed from the widget via Polkit.

![](screenshots/pacman.gif)

## Requirements
`lxpolkit` is the default [Polkit agent](https://wiki.archlinux.org/title/Polkit).

The widget also uses the `checkupdates` script from the `pacman-contrib` package.


## Installation

Clone the repo under **~/.config/awesome/** and add the following to **rc.lua**:

```lua
local pacman_widget = require('pacman-widget.pacman')
...
s.mytasklist, -- Middle widget
	{ -- Right widgets
    	layout = wibox.layout.fixed.horizontal,
        ...
        -- default
        pacman_widget(),
        -- custom (shown with defaults)
        pacman_widget {
            interval = 600,	-- Refresh every 10 minutes
            popup_bg_color = '#222222',
            popup_border_width = 1,
            popup_border_color = '#7e7e7e',
            popup_height = 10,	-- 10 packages shown in scrollable window
            popup_width = 300,
            polkit_agent_path = '/usr/bin/lxpolkit'
        },
```

