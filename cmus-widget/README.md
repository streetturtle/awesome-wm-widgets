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
awful.key({ modkey, "Shift" }, "p",              function () cmus_widget:play_pause() end, {description = "toggle track",   group = "cmus"}),
awful.key({                 }, "XF86AudioPlay",  function () cmus_widget:play()       end, {description = "play track",     group = "cmus"}),
awful.key({                 }, "XF86AudioPause", function () cmus_widget:play()       end, {description = "pause track",    group = "cmus"}),
awful.key({                 }, "XF86AudioNext",  function () cmus_widget:next_track() end, {description = "next track",     group = "cmus"}),
awful.key({                 }, "XF86AudioPrev",  function () cmus_widget:prev_track() end, {description = "previous track", group = "cmus"}),
awful.key({                 }, "XF86AudioStop",  function () cmus_widget:stop()       end, {description = "stop track",      group = "cmus"}),
```

## Customization

It is possible to customize the widget by providing a table with all or some of the following config parameters:

### Generic parameter

| Name | Default | Description |
|---|---|---|
| `font` | `beautiful.font` | Font name and size, like `Play 12` |
| `path_to_icons` | `/usr/share/icons/Arc/actions/symbolic/` | Alternative path for the icons |
| `timeout`| `10` | Refresh cooldown |
| `max_length` | `30` | Maximum lentgh of title. Text will be ellipsized if longer. |
| `space` | `3` | Space between icon and track title |
