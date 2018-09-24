---
layout: page
---
# Spotify widget

This widget displays currently playing song on [Spotify for Linux](https://www.spotify.com/download/linux/) client: ![screenshot]({{'/assets/img/screenshots/spotify-widget.png' | relative_url }}) and consists of two parts:

 - status icon which shows if music is currently playing
 - artist and name of the current song playing

## Controls

 - left click - play/pause
 - scroll up - play next song
 - scroll down - play previous song

## Dependencies

Note that widget uses the Arc icon theme, so it should be [installed](https://github.com/horst3180/arc-icon-theme#installation) first under **/usr/share/icons/Arc/** folder.

## Installation

1. Install [sp](https://gist.github.com/streetturtle/fa6258f3ff7b17747ee3) - CLI client for [Spotify for Linux](https://www.spotify.com/ca-en/download/linux/):

    ```bash
    $ sudo git clone https://gist.github.com/fa6258f3ff7b17747ee3.git ~/dev/
    $ sudo ln -s ~/dev/sp /usr/local/bin/
    ```

    Check if it works by running `sp help`.

1. Get an 'id' and 'secret' from [developer.spotify.com](https://beta.developer.spotify.com/documentation/general/guides/app-settings/) and paste it in the header of the `sp` (`SP_ID` and `SP_SECRET`) - this enables search feature.

1. Clone this repo under **~/.config/awesome/**

    ```bash
    git clone https://github.com/streetturtle/awesome-wm-widgets.git ~/.config/awesome/
    ```

1. Require spotify-widget at the beginning of **rc.lua**:

    ```lua
    local spotify_widget = require("awesome-wm-widgets.spotify-widget.spotify")
    ```

1. Add widget to the tasklist:

    ```lua
    s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            ...
            spotify_widget,
            ...
    ```

