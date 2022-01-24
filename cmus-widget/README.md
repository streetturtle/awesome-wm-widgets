# Cmus widget

Cmus widget that shows the current playing track.

![widget](./screenshots/cmus-widget.png)

Left click toggles playback.

## Installation

Clone the repo under **~/.config/awesome/** and add widget in **rc.lua**:

```lua
local cmus_widget = require('awesome-wm-widgets.cmus-widget.cmus')
...
s.mytasklist, -- Middle widget
    { -- Right widgets
    	layout = wibox.layout.fixed.horizontal,
        ...
        -- default
        cmus_widget(),
        -- customized
        cmus_widget{
            space = 5,
            timeout = 5
        },
```

### Shortcuts

To improve responsiveness of the widget when playback is changed by a shortcut use corresponding methods of the widget:

```lua
awful.key({ modkey, "Shift"   }, 
        "p", 
        function() cmus_widget:play_pause() end, 
        {description = "play/pause cmus", group = "custom"}),
```

## Customization

It is possible to customize the widget by providing a table with all or some of the following config parameters:

### Generic parameter

| Name | Default | Description |
|---|---|---|
| `font` | `Play 9` | Font used for the track title |
| `path_to_icons` | `/usr/share/icons/Arc/actions/symbolic/` | Alternative path for the icons |
| `timeout`| `10` | Refresh cooldown |
| `space` | `3` | Space between icon and track title |
