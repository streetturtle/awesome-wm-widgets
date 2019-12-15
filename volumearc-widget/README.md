# Volumearc widget

Almost the same as [volumebar widget](https://github.com/streetturtle/awesome-wm-widgets/tree/master/volumebar-widget), but using [arcchart](https://awesomewm.org/doc/api/classes/wibox.container.arcchart.html):

![screenshot](./out.gif)

Supports 
 - scroll up - increase volume, 
 - scroll down - decrease volume, 
 - left click - mute/unmute.

## Customization

It is possible to customize widget by providing a table with all or some of the following config parameters:

| Name | Default | Description |
|---|---|---|
| `main_color` | `beautiful.fg_normal` | Color of the arc |
| `mute_color` | `beautiful.fg_urgent` | Color of the arc when mute |
| `path_to_icon` | /usr/share/icons/Arc/status/symbolic/audio-volume-muted-symbolic.svg | Path to the icon |
| `thickness` | 2 | The arc thickness |
| `height` | `beautiful.fg_normal` | Widget height |
| `get_volume_cmd` | `amixer -D pulse sget Master` | Get current volume level |
| `inc_volume_cmd` | `amixer -D pulse sset Master 5%+` | Increase volume level |
| `dec_volume_cmd` | `amixer -D pulse sset Master 5%-` | Decrease volume level |
| `tog_volume_cmd` | `amixer -D pulse sset Master toggle` | Mute / unmute |

### Example:

```lua
volumearc_widget({
    main_color = '#af13f7',
    mute_color = '#ff0000',
    thickness = 5,
    height = 25
})
```

The config above results in the following widget:

![custom](./custom.png) 

## Installation

1. Clone this repo under **~/.config/awesome/**

    ```bash
    git clone https://github.com/streetturtle/awesome-wm-widgets.git ~/.config/awesome/
    ```

1. Require volumearc widget at the beginning of **rc.lua**:

```lua
require("volumearc")
...
s.mytasklist, -- Middle widget
	{ -- Right widgets
    	layout = wibox.layout.fixed.horizontal,
		...
		volumearc_widget,
		...
```
