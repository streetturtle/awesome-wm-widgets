---
layout: page
---
# Volumearc widget

Almost the same as [volumebar widget](https://github.com/streetturtle/awesome-wm-widgets/tree/master/volumebar-widget), but using arcchart:

![screenshot]({{'/assets/img/screenshots/volumearc-widget.gif' | relative_url }}){:.center-image}

## Installation

1. Clone this repo under **~/.config/awesome/**

    ```bash
    git clone https://github.com/streetturtle/awesome-wm-widgets.git ~/.config/awesome/
    ```

1. Require volumearc widget at the beginning of **rc.lua**:

    ```lua
    local volumearc_widget = require("awesome-wm-widgets.volumearc-widget.volumearc")
    ```

1. Add widget to the tasklist:

    ```lua
    s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            ...
            volumearc_widget,
            ...
    ```

## Control volume

To mute/unmute click on the widget. To increase/decrease volume scroll up or down when mouse cursor is over the widget.

If you want to control volume level by keyboard shortcuts add following lines in shortcut section of the **rc.lua** (the commands could be slightly different depending on your PC configuration):

```lua
awful.key({ modkey}, "[", function () awful.spawn("amixer -D pulse sset Master 5%-") end, {description = "increase volume", group = "custom"}),
awful.key({ modkey}, "]", function () awful.spawn("amixer -D pulse sset Master 5%+") end, {description = "decrease volume", group = "custom"}),
awful.key({ modkey}, "\", function () awful.spawn("amixer -D pulse set Master +1 toggle") end, {description = "mute volume", group = "custom"}),
```
