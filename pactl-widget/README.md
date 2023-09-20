# Pactl volume widget

This is a volume widget that uses `pactl` only for controlling volume and
selecting sinks and sources. Hence, it can be used with PulseAudio or PipeWire
likewise, unlike the original Volume widget.

Other than that it is heavily based on the original widget, including its
customization and icon options. For screenshots, see the original widget.

## Installation

Clone the repo under **~/.config/awesome/** and add widget in **rc.lua**:

```lua
local volume_widget = require('awesome-wm-widgets.pactl-widget.volume')
...
s.mytasklist, -- Middle widget
	{ -- Right widgets
    	layout = wibox.layout.fixed.horizontal,
        ...
        -- default
        volume_widget(),
        -- customized
        volume_widget{
            widget_type = 'arc'
        },
```

### Shortcuts

To improve responsiveness of the widget when volume level is changed by a shortcut use corresponding methods of the widget:

```lua
awful.key({}, "XF86AudioRaiseVolume", function () volume_widget:inc(5) end),
awful.key({}, "XF86AudioLowerVolume", function () volume_widget:dec(5) end),
awful.key({}, "XF86AudioMute", function () volume_widget:toggle() end),
```

## Customization

It is possible to customize the widget by providing a table with all or some of
the following config parameters:

### Generic parameter

| Name | Default | Description |
|---|---|---|
| `mixer_cmd` | `pavucontrol` | command to run on middle click (e.g. a mixer program) |
| `step` | 5 | How much the volume is raised or lowered at once (in %) |
| `widget_type`| `icon_and_text`| Widget type, one of `horizontal_bar`, `vertical_bar`, `icon`, `icon_and_text`, `arc` |
| `device` | `@DEFAULT_SINK@` | Select the device name to control |
| `tooltip` | false | Display volume level in a tooltip when the mouse cursor hovers the widget |

For more details on parameters depending on the chosen widget type, please
refer to the original Volume widget.
