---
layout: page
---
# CPU widget

This widget shows the average CPU load among all cores of the machine:

![screenshot]({{'/assets/img/screenshots/cpu-widget.gif' | relative_url }})

When the load is more than 80% the graph becomes red. You can easily customize the widget by changing colors, step width, step spacing, width and interval.

## How it works

To measure the load I took Paul Colby's bash [script](http://colby.id.au/calculating-cpu-usage-from-proc-stat/) and rewrote it in Lua, which was quite simple.
So awesome simply reads the first line of /proc/stat:

```bash
$ cat /proc/stat | grep '^cpu '
cpu  197294 718 50102 2002182 3844 0 2724 0 0 0
```

and calculates the percentage.

## Installation

1. Clone this repo under **~/.config/awesome/**

    ```bash
    git clone https://github.com/streetturtle/awesome-wm-widgets.git ~/.config/awesome/
    ```

1. Require spotify-widget at the beginning of **rc.lua**:

    ```lua
    local cpu_widget = require("awesome-wm-widgets.cpu-widget.cpu-widget")
    ```

1. Add widget to the tasklist:

    ```lua
    s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            ...
            cpu_widget,
            ...
    ```
