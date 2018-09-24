---
layout: page
---
# Volumebar widget

Almost the same as volume widget, but more minimalistic:

![screenshot]({{'/assets/img/screenshots/volumebar-widget.gif' | relative_url }}){:.center-image}

Supports 
 - scroll up - increase volume, 
 - scroll down - decrease volume, 
 - left click - mute/unmute.
 
## Installation

1. Clone this repo under **~/.config/awesome/**

    ```bash
    git clone https://github.com/streetturtle/awesome-wm-widgets.git ~/.config/awesome/
    ```

1. Require volumearc widget at the beginning of **rc.lua**:

    ```lua
    local volumebar_widget = require("awesome-wm-widgets.volumebar-widget.volumebar")
    ```

1. Add widget to the tasklist:

    ```lua
    s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            ...
            volumebar_widget,
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

## Troubleshooting

If the bar is not showing up, try to decrease top or bottom margin - widget uses hardcoded margins for vertical alignment, so if your wibox is too small then bar is simply hidden by the margins.
