# Spotify widget

This widget displays currently playing song on [Spotify for Linux](https://www.spotify.com/download/linux/) client: ![screenshot](./spo-wid-1.png) and consists of two parts: 

 - status icon which shows if music is currently playing
 - artist and name of the current song playing

## Controls

 - left click - play/pause
 - scroll up - play next song
 - scroll down - play previous song

## Dependencies

Note that widget uses the Arc icon theme, so it should be [installed](https://github.com/horst3180/arc-icon-theme#installation) first under **/usr/share/icons/Arc/** folder.

## Installation

First you need to have spotify CLI installed. Here is how you can do it (except widget part): [pavelmakhov.com/2016/02/awesome-wm-spotify](http://pavelmakhov.com/2016/02/awesome-wm-spotify) 

To use this widget clone repo under **~/.config/awesome/** and then add it in **rc.lua**:

```lua
local spotify_widget = require("awesome-wm-widgets.spotify-widget.spotify")
...
s.mytasklist, -- Middle widget
	{ -- Right widgets
    	layout = wibox.layout.fixed.horizontal,
		...
        spotify_widget,
		...      
```
