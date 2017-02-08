# Volume widget

Simple and easy-to-install widget for Awesome Window Manager which represents the sound level: ![Volume Widget](
./vol-widget-1.png)

Note that widget uses the Arc icon theme, so it should be [installed](https://github.com/horst3180/arc-icon-theme#installation) first under **/usr/share/icons/Arc/** folder.

## Installation

- clone/copy **volume.lua** file;

- include `volume.lua` and add volume widget to your wibox in rc.lua:

```lua
require("volume")
...
s.mytasklist, -- Middle widget
	{ -- Right widgets
    	layout = wibox.layout.fixed.horizontal,
		...
		volume_widget,
		...      
```

## Control volume

To be able to control volume level add following lines in shortcut section of the **rc.lua** (the command could be slightly different depending on your pc configuration):

```lua
awful.key({ modkey}, "[", function () awful.spawn("amixer -D pulse sset Master 5%-") end, {description = "increase volume", group = "custom"}),
awful.key({ modkey}, "]", function () awful.spawn("amixer -D pulse sset Master 5%+") end, {description = "decrease volume", group = "custom"}),
```
