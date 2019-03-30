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
            --[[default]]
            volumearc_widget(),
            --[[or customized]]
            volumearc_widget({
                main_color = '#0000ff',
                mute_color = '#ff0000',
                path_to_icon = '/usr/share/icons/Arc/actions/symbolic/view-grid-symbolic.svg',
                thickness = 5,
                height = 25
            }),

            ...
    ```