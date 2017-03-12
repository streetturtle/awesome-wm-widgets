---
layout: page
---

# AwesomeWM

Set of super simple widgets compatible with Awesome Window Manager v.4.

![screenshot](https://github.com/streetturtle/AwesomeWM/blob/master/screenshot.png?raw=true)

From left to right:

- [spotify-widget](https://github.com/streetturtle/AwesomeWM/tree/master/spotify-widget) / [rhythmbox-widget](https://github.com/streetturtle/AwesomeWM/tree/master/rhythmbox-widget)
- [weather-widget](https://github.com/streetturtle/AwesomeWM/tree/master/weather-widget)
- [email-widget](https://github.com/streetturtle/AwesomeWM/tree/master/email-widget)
- [brightness-widget](https://github.com/streetturtle/AwesomeWM/tree/master/brightness-widget)
- [volume-widget](https://github.com/streetturtle/AwesomeWM/tree/master/volume-widget)
- [battery-widget](https://github.com/streetturtle/AwesomeWM/tree/master/battery-widget)

These widgets use [Arc icon theme](https://github.com/horst3180/arc-icon-theme) by default but it could be easily 
changed to any other icon theme. If you want to have separators between widgets like on the screenshot create text widget with ` : ` and place it between widgets:

```lua
...
sprtr = wibox.widget.textbox()
sprtr:set_text(" : ")
...
sprtr,
volume_icon,
sprtr,
battery_widget,
sprtr,
...
```

# Installation

[Install](https://github.com/horst3180/arc-icon-theme#installation) Arc icon theme and follow installation instructions of each widget.
