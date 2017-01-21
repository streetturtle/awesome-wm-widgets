# AwesomeWM

Set of simple widgets for Awesome Window Manager consists of following widgets:

 - [Battery Widget](https://github.com/streetturtle/AwesomeWM#battery-widget)
 - [Email Widget](https://github.com/streetturtle/AwesomeWM#email-widget)
 - [Mouse Battery Widget](https://github.com/streetturtle/AwesomeWM#mouse-battery-widget)
 - [Rates Widget](https://github.com/streetturtle/AwesomeWM#rates-widget)
 - [Spotify Widget](https://github.com/streetturtle/AwesomeWM#spotify-widget)
 - [Volume Control Widget](https://github.com/streetturtle/AwesomeWM#volume-control-widget)

Note that these widgets work with Awesome WM 3.5 version. I'm currently migrating them to 4.0.

## Battery widget

This widget consists of

 - an icon which shows the battery status: ![Battery Widget](https://raw.githubusercontent.com/streetturtle/AwesomeWM/master/BatteryWidget/batWid1.png)
 - a pop-up window, which shows up when you hover over it: ![Battery Widget](https://raw.githubusercontent.com/streetturtle/AwesomeWM/master/BatteryWidget/batWid2.png)
 - a pop-up warning message which appears when battery level is less that 15%: ![Battery Widget](https://raw.githubusercontent.com/streetturtle/AwesomeWM/master/BatteryWidget/batWid3.png)

**Installation**

This widget uses the output of acpi tool.
- install `acpi` tool:
```
sudo apt-get install acpi
```
- clone/copy battery.lua file and battery-icons folder to your ~/home/username/.config/awesome/ folder;

- change path to the icons in `battery.lua`;

- include `battery.lua` and add battery widget to your wibox in rc.lua:
```
require("battery")
...
right_layout:add(batteryIcon)
```

---

## Email widget

This widget consists of an icon with counter which shows number of unread emails: ![email icon](https://raw.githubusercontent.com/streetturtle/AwesomeWM/master/EmailWidget/emailWidgetScrnsht.png)
and a popup message which appears when mouse hovers over an icon: ![email popup](https://raw.githubusercontent.com/streetturtle/AwesomeWM/master/EmailWidget/emailWidgetScrnsht2.png)

**Installation**

To install it either clone [EmailWidget](https://github.com/streetturtle/AwesomeWM/tree/master/EmailWidget) project under `~/.config/awesome/` or download a .zip archive and unzip it there.

After provide your credentials in python scripts so that they could connect to server and add following lines in your **rc.lua** file:

```lua
require("email")
...
right_layout:add(emailWidget_icon)
right_layout:add(emailWidget_counter)
```

**How it works**

This widget uses the output of two python scripts, first is called every 5 seconds - it returns number of unread emails and second is called when mouse hovers over an icon and displays content of those emails. For both of them you'll need to provide your credentials and imap server. For testing they can simply be called from console:

```bash
python ~/.config/awesome/email/countUnreadEmails.py
python ~/.config/awesome/email/readEmails.py
```

Note that getting number of unread emails could take some time, so instead of `pread` or `spawn_with_shell` functions I use DBus, you can read more about it in [this](http://pavelmakhov.com/2015/09/fix-awesome-freezes) post.

---

## Mouse Battery Widget

This widget shows the battery status of wireless mouse: ![screenshot](https://raw.githubusercontent.com/streetturtle/AwesomeWM/master/MouseBatteryWidget/mouse-battery.png)

 Include `mouse-battery` and add battery widget to your wibox in rc.lua (you can use both icon and text, or any of them separately):

```lua
require("mouse-battery")
...
right_layout:add(mouse_battery_icon) -- icon
right_layout:add(mouse_widget)       -- text
```

Read more about how it works here: [Mouse Battery status widget for Awesome WM](http://pavelmakhov.com/2017/01/awesome-wm-mouse-battery)

---

## Rates widget

Rates widget showing currency rate for chosen currencies with pop-up appearing when mouse hovers over it.
More about this widget in this two posts:
 - http://pavelmakhov.com/2016/01/how-to-create-widget
 - http://pavelmakhov.com/2016/01/how-to-create-widget-part-2  

---

## Spotify widget

Widget displaying currently playing song by Spotify application:
![screenshot](https://raw.githubusercontent.com/streetturtle/AwesomeWM/master/Spotify/screenshot.png)

You can read more about spotify integration in this blog [post](http://pavelmakhov.com/2016/02/awesome-wm-spotify).

---

## Volume control widget

Simple and easy-to-install widget for Awesome Window Manager.
This widget represents the sound level: ![Volume Wiget](https://github.com/streetturtle/AwesomeWM/raw/master/VolumeWidget/volWid.png)

**Installation**

- clone/copy volume.lua file and volume-icons folder to your `~/home/username/.config/awesome/` folder;

- change path to the icons in `volume.lua`:

```
widget:set_image("/home/<username>/.config/awesome/volume-icons/" .. volumeLevel .. ".png")
```

- include `volume.lua` and add volume widget to your wibox in rc.lua:

```
require("volume")
...
right_layout:add(volumeWidget)
```
