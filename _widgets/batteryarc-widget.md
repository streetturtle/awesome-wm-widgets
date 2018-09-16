---
layout: page
---

# Batteryarc widget

This widget is more informative version of [battery widget](https://github.com/streetturtle/awesome-wm-widgets/tree/master/battery-widget).

Depending of the battery status it may look one of the following ways:

 - ![10_d]({{'/assets/img/screenshots/batteryarc-10_d.png' | relative_url }}) - less than 15 percent
 - ![10_c]({{'/assets/img/screenshots/batteryarc-10_c.png' | relative_url }}) - less than 15 percent, charging
 - ![20_d]({{'/assets/img/screenshots/batteryarc-20_d.png' | relative_url }}) - between 15 and 40 percent
 - ![20_c]({{'/assets/img/screenshots/batteryarc-20_c.png' | relative_url }}) - between 15 and 40 percent, charging
 - ![80_d]({{'/assets/img/screenshots/batteryarc-80_d.png' | relative_url }}) - more than 40 percent
 - ![80_c]({{'/assets/img/screenshots/batteryarc-80_c.png' | relative_url }}) - more than 40 percent, charging

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
local batteryarc_widget = require("awesome-wm-widgets.batteryarc-widget.batteryarc")
...
s.mytasklist, -- Middle widget
	{ -- Right widgets
    	layout = wibox.layout.fixed.horizontal,
		...
		batteryarc_widget,
		...
```
You can get the icon for warning popup [here](https://vk.com/images/stickers/1933/512.png)

## Troubleshooting

In case of any doubts or questions don't hesitate to raise an [issue](https://github.com/streetturtle/awesome-wm-widgets/issues/new).
