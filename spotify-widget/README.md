# Spotify widget

This widget displays currently playing song on [Spotify for Linux](https://www.spotify.com/download/linux/) client: ![screenshot](./spo-wid-default.png) and consists of two parts: 

 - status icon which shows if music is currently playing
 - artist and name of the current song

## Controls

 - left click - play/pause
 - scroll up - play next song
 - scroll down - play previous song

## Dependencies

Note that widget uses the Arc icon theme, so it should be [installed](https://github.com/horst3180/arc-icon-theme#installation) first under **/usr/share/icons/Arc/** folder.

## Customization

It is possible to customize widget by providing a table with all or some of the following config parameters:

| Name | Default | Description |
|---|---|---|
| `play_icon` | `/usr/share/icons/Arc/actions/24/player_play.png` | Play icon |
| `pause_icon` | `/usr/share/icons/Arc/actions/24/player_pause.png` | Pause icon |
| `font` | `Play 9`| Font |

### Example:

```lua
spotify_widget({
    font = 'Ubuntu Mono 9',
    play_icon = '/usr/share/icons/Papirus-Light/24x24/categories/spotify.svg',
    pause_icon = '/usr/share/icons/Papirus-Dark/24x24/panel/spotify-indicator.svg'
})
```

Gives following widget:

![screenshot](./spo-wid-custom.png)

## Installation

First you need to have spotify CLI installed, it uses dbus to communicate with spotify-client:

```bash 
git clone https://gist.github.com/fa6258f3ff7b17747ee3.git
cd ./fa6258f3ff7b17747ee3 
chmod +x sp
sudo cp ./sp /usr/local/bin/
```

Then clone repo under **~/.config/awesome/** and add widget in **rc.lua**:

```lua
local spotify_widget = require("awesome-wm-widgets.spotify-widget.spotify")
...
s.mytasklist, -- Middle widget
	{ -- Right widgets
    	layout = wibox.layout.fixed.horizontal,
		...
        -- default        
        spotify_widget(),
        -- customized
        spotify_widget({
           font = 'Ubuntu Mono 9',
           play_icon = '/usr/share/icons/Papirus-Light/24x24/categories/spotify.svg',
           pause_icon = '/usr/share/icons/Papirus-Dark/24x24/panel/spotify-indicator.svg'
        }),
		...      
```
