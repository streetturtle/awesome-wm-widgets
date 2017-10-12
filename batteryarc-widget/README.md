# Batteryarc widget

This widget is more informative version of [battery widget](https://github.com/streetturtle/awesome-wm-widgets/tree/master/battery-widget).

Depending of the battery status it could look following ways:

 - ![10_d](./10_d.png) - less than 15 percent
 - ![10_c](./10_c.png) - less than 15 percent, charging
 - ![20_d](./20_d.png) - between 15 and 40 percent
 - ![20_c](./20_c.png) - between 15 and 40 percent, charging
 - ![80_d](./80_d.png) - more than 40 percent
 - ![80_c](./80_c.png) - more than 40 percent, charging

Widget uses following beautiful variables with values:

```lua
theme.widget_main_color = "#74aeab"
theme.widget_red = "#e53935"
theme.widget_yellow = "#c0ca33"
theme.widget_green = "#43a047"
theme.widget_black = "#000000"
theme.widget_transparent = "#00000000"
```

which means that you need to copy the code above and paste it in your **theme.lua**. Otherwise you can change colors directly in the widget.

## Installation

Clone repo, include widget and use it in **rc.lua**:

```lua
require("volumearc")
...
s.mytasklist, -- Middle widget
	{ -- Right widgets
    	layout = wibox.layout.fixed.horizontal,
		...
		batteryarc_widget,
		...
```

## Troubleshooting

In case of any doubts or questions don't hesitate to raise an [issue](https://github.com/streetturtle/awesome-wm-widgets/issues/new).
