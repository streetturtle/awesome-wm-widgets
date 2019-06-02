# Batteryarc widget

This widget is more informative version of [battery widget](https://github.com/streetturtle/awesome-wm-widgets/tree/master/battery-widget).

Depending of the battery status it could look following ways:

 - ![10_d](./10_d.png) - less than 15 percent
 - ![10_c](./10_c.png) - less than 15 percent, charging
 - ![20_d](./20_d.png) - between 15 and 40 percent
 - ![20_c](./20_c.png) - between 15 and 40 percent, charging
 - ![80_d](./80_d.png) - more than 40 percent
 - ![80_c](./80_c.png) - more than 40 percent, charging

If a battery level is low then warning popup will show up:

![warning](./warning.png)

## Customization

It is possible to customize widget by providing a table with all or some of the following config parameters:

| Name | Default | Description |
|---|---|---|
| `font` | Font | Play 6 |
| `arc_thickness` | Thickness of the arc | 2 |
| `show_current_level`| Show current charge level | false |
| `main_color` | Color of the text with the current charge level and the arc| `beautiful.fg_color` |
| `low_level_color` | Arc color when battery charge is less that 15%| #e53935 |
| `medium_level_color` | Arc color when battery charge is between 15% and 40% | #c0ca33 |
| `charging` | Color of the circle inside the arc when charging | `beautiful.fg_color` |
| `warning_msg_title` | Title of the warning popup | _Huston, we have a problem_ |
| `warning_msg_text` | Text of the warning popup | _Battery is dying_ |
| `warning_msg_position` | Position of the warning popup | `bottom_right` |
| `warning_msg_icon` | Icon of the warning popup| ~/.config/awesome/awesome-wm-widgets/batteryarc-widget/spaceman.jpg |


## Installation

Clone repo, include widget and use it in **rc.lua**:

```lua
local batteryarc_widget = require("awesome-wm-widgets.batteryarc-widget.batteryarc")
...
s.mytasklist, -- Middle widget
	{ -- Right widgets
    	layout = wibox.layout.fixed.horizontal,
		...
        --[[default]]
		batteryarc_widget(),		
        --[[or customized]]
        batteryarc_widget({
            show_current_level = true,
            thickness = '1',
        }),
	}
	...
```

## Troubleshooting

In case of any doubts or questions please raise an [issue](https://github.com/streetturtle/awesome-wm-widgets/issues/new).
