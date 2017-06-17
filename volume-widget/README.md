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

- _Optional step._ In Arc icon theme the muted audio level icon (![Volume-widget](./audio-volume-muted-symbolic.png)) looks like 0 level icon, which could be a bit misleading.
 So I decided to use original muted icon for low audio level, and the same icon, but colored in red for muted audio level. Fortunately icons are in svg format, so you can easily recolor them with `sed`, so it would look like this (![Volume Widget](./audio-volume-muted-symbolic_red.png)):
 
 ```bash
 cd /usr/share/icons/Arc/status/symbolic && 
 sudo cp audio-volume-muted-symbolic.svg audio-volume-muted-symbolic_red.svg && 
 sudo sed -i 's/bebebe/ed4737/g' ./audio-volume-muted-symbolic_red.svg 
 ```

## Control volume

To mute/unmute click on the widget. To increase/decrease volume scroll up or down when mouse cursor is over the widget.

If you want to control volume level by keyboard shortcuts add following lines in shortcut section of the **rc.lua** (the commands could be slightly different depending on your PC configuration):

```lua
awful.key({ modkey}, "[", function () awful.spawn("amixer -D pulse sset Master 5%-") end, {description = "increase volume", group = "custom"}),
awful.key({ modkey}, "]", function () awful.spawn("amixer -D pulse sset Master 5%+") end, {description = "decrease volume", group = "custom"}),
awful.key({ modkey}, "\", function () awful.spawn("amixer -D pulse set Master +1 toggle") end, {description = "mute volume", group = "custom"}),
```
