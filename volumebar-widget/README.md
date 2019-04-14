# Volumebar widget

Almost the same as volume widget, but more minimalistic:

![screenshot](out.gif)

Supports 
 - scroll up - increase volume, 
 - scroll down - decrease volume, 
 - left click - mute/unmute.
 
 ## Customization
 
 It is possible to customize widget by providing a table with all or some of the following config parameters:
 
 ```lua
 volumebar_widget({
    main_color = '#af13f7',
    mute_color = '#ff0000',
    width = 80,
    shape = 'rounded_bar', -- octogon, hexagon, powerline, etc
    -- bar's height = wibar's height minus 2x margins
    margins = 8
})
 ```

Above config results in following widget:

![custom](./custom.png) 


 ## Installation
 
1. Clone this repo under **~/.config/awesome/**

    ```bash
    git clone https://github.com/streetturtle/awesome-wm-widgets.git ~/.config/awesome/
    ```

1. Require volumebar widget at the beginning of **rc.lua**:

    ```lua
    local volumebar_widget = require("awesome-wm-widgets.volumebar-widget.volumebar")
    ```

1. Add widget to the tasklist:

    ```lua
    s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            ...
            --[[default]]
            volumebar_widget(),
            --[[or customized]]
            volumebar_widget({
                main_color = '#af13f7',
                mute_color = '#ff0000',
                width = 80,
                shape = 'rounded_bar', -- octogon, hexagon, powerline, etc
                -- bar's height = wibar's height minus 2x margins
                margins = 8
            }),

            ...
    ```

## Troubleshooting

If the bar is not showing up, try to decrease top or bottom margin - widget uses hardcoded margins for vertical alignment, so if your wibox is too small then bar is simply hidden by the margins.
