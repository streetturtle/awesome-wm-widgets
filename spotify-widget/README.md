# Spotify widget

This widget displays currently playing song on [Spotify for Linux](https://www.spotify.com/download/linux/) client: ![screenshot](./spo-wid-1.png).

If clicked plays/pauses the music.

Note that widget uses the Arc icon theme, so it should be [installed](https://github.com/horst3180/arc-icon-theme#installation) first under **/usr/share/icons/Arc/** folder.

## Installation

First you need to have spotify CLI installed. Here is how you can do it (except widget part): [pavelmakhov.com/2016/02/awesome-wm-spotify](http://pavelmakhov.com/2016/02/awesome-wm-spotify) 

To use this widget put **spotify.lua** under **~/.config/awesome/** and add it in **rc.lua**:

```lua
require("spotify")
...
s.mytasklist, -- Middle widget
	{ -- Right widgets
    	layout = wibox.layout.fixed.horizontal,
		...
        spotify_widget,
		...      
```
