# Volumearc widget

Almost the same as [volumebar widget](https://github.com/streetturtle/awesome-wm-widgets/tree/master/volumebar-widget), but using arcchart:

![screenshot](out.gif)

## Customization

It is possible to customize widget by providing a table with all or some of the following config parameters:

```lua
volumearc_widget({
    main_color = '#af13f7',
    mute_color = '#ff0000',
    path_to_icon = '/usr/share/icons/Papirus-Dark/symbolic/status/audio-volume-high-symbolic.svg',
    thickness = 5,
    height = 25
})
```

Above config results in following widget:

![custom](./custom.png) 

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
                main_color = '#af13f7',
                mute_color = '#ff0000',
                path_to_icon = '/usr/share/icons/Papirus-Dark/symbolic/status/audio-volume-high-symbolic.svg',
                thickness = 5,
                height = 25
            }),

            ...
    ```
