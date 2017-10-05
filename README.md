# AwesomeWM

Set of super simple widgets compatible with Awesome Window Manager v.4+. 

![screenshot](https://github.com/streetturtle/AwesomeWM/blob/master/screenshot.png?raw=true)

From left to right:

- [spotify-widget](https://github.com/streetturtle/AwesomeWM/tree/master/spotify-widget) / [rhythmbox-widget](https://github.com/streetturtle/AwesomeWM/tree/master/rhythmbox-widget)
- [weather-widget](https://github.com/streetturtle/AwesomeWM/tree/master/weather-widget)
- [email-widget](https://github.com/streetturtle/AwesomeWM/tree/master/email-widget)
- [brightness-widget](https://github.com/streetturtle/AwesomeWM/tree/master/brightness-widget)
- [volume-widget](https://github.com/streetturtle/AwesomeWM/tree/master/volume-widget)
- [volumebar-widget](https://github.com/streetturtle/AwesomeWM/tree/master/volumebar-widget) (not on the screenshot)
- [volumearc-widget](https://github.com/streetturtle/AwesomeWM/tree/master/volumearc-widget) (not on the screenshot)
- [battery-widget](https://github.com/streetturtle/AwesomeWM/tree/master/battery-widget)
- [batteryarc-widget](https://github.com/streetturtle/AwesomeWM/tree/master/batteryarc-widget) (not on the screenshot)
- [cpu-widget](https://github.com/streetturtle/AwesomeWM/tree/master/cpu-widget) (not on the screenshot)

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

Or you can clone this repo under **~/.config/awesome/** and then add widgets you'd like to use in wibox:

```bash
cd ~/.config/awesome/
git clone https://github.com/streetturtle/awesome-wm-widgets.git
```

and in **rc.lua**

```lua
require("awesome-wm-widgets.battery-widget.battery")
...
 -- Add widgets to the wibox
     s.mywibox:setup {
         layout = wibox.layout.align.horizontal,
         { -- Left widgets
         ...
         },
         s.mytasklist, -- Middle widget
         { -- Right widgets
         ...
             battery_widget,
         ...
         }
```

# Icons

If you don't want to install Arc icon theme you can just download the icons which are used from the [Arc repository](https://github.com/horst3180/arc-theme).
Or create your own icons with the same name.

In case of any questions/suggestions don't hesitate to contact me, I would be happy to help :)

PRs/issues and st★rs are welcome!
