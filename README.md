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
Or create your own icons with the same name. Here is the list of icons used:

<table>
  <tr>
    <th>Widget</th>
    <th>Icon name</th>
    <th>Arc Path</th>
  </tr>
  <tr>
    <td rowspan="2">email-widget</td>
    <td>mail-message-new.png<br></td>
    <td rowspan="2">/usr/share/icons/Arc/actions/22/</td>
  </tr>
  <tr>
    <td>mail-mark-unread.png</td>
    <td></td>
  </tr>
  <tr>
    <td>brightness-widget</td>
    <td>display-brightness-symbolic.svg</td>
    <td>/usr/share/icons/Arc/status/symbolic/</td>
  </tr>
  <tr>
    <td rowspan="4">volume-widget</td>
    <td>audio-volume-muted-symbolic.svg</td>
    <td rowspan="4">/usr/share/icons/Arc/status/symbolic/</td>
  </tr>
  <tr>
    <td>audio-volume-low-symbolic.svg</td>
    <td></td>
  </tr>
  <tr>
    <td>audio-volume-medium-symbolic.svg</td>
    <td></td>
  </tr>
  <tr>
    <td>audio-volume-high-symbolic.svg</td>
    <td></td>
  </tr>
  <tr>
    <td rowspan="8">battery-widget</td>
    <td>battery-caution-symbolic.svg</td>
    <td rowspan="8">/usr/share/icons/Arc/status/symbolic/</td>
  </tr>
  <tr>
    <td>battery-caution-charging-symbolic.svg</td>
    <td></td>
  </tr>
  <tr>
    <td>battery-low-symbolic.svg</td>
    <td></td>
  </tr>
  <tr>
    <td>battery-low-charging-symbolic.svg</td>
    <td></td>
  </tr>
  <tr>
    <td>battery-good-symbolic.svg</td>
    <td></td>
  </tr>
  <tr>
    <td>battery-good-charging-symbolic.svg</td>
    <td></td>
  </tr>
  <tr>
    <td>battery-full-symbolic.svg</td>
    <td></td>
  </tr>
  <tr>
    <td>battery-full-charging-symbolic.svg</td>
    <td></td>
  </tr>
</table>

In case of any questions/suggestions don't hesitate to contact me, I would be happy to help :)

PRs/issues and st★rs are welcome!
