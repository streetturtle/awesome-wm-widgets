---
layout: page
---

# Spotify widget

This widget displays currently playing song on [Spotify for Linux](https://www.spotify.com/download/linux/) client: ![screenshot](https://github.com/streetturtle/AwesomeWM/blob/master/spotify-widget/spo-wid-1.png?raw=true).

Note that widget uses the Arc icon theme, so it should be [installed](https://github.com/horst3180/arc-icon-theme#installation) first under **/usr/share/icons/Arc/** folder.

## Installation

First you need to have spotify CLI installed. To do it put following file under **/usr/local/bin** and make it executable:

```bash
git clone https://gist.github.com/fa6258f3ff7b17747ee3.git
sudo mv ./fa6258f3ff7b17747ee3/sp /usr/local/bin/
sudo chmod +x /usr/local/bin/sp
```

To use this widget put **spotify.lua** under **~/.config/awesome/** and add it in **rc.lua**:

{% highlight lua %}
require("spotify")
...
s.mytasklist, -- Middle widget
	{ -- Right widgets
    	layout = wibox.layout.fixed.horizontal,
		...
        spotify_widget,
		...      
{% endhighlight %}
