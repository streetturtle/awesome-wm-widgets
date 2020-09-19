# Stackoverflow widget

When clicked, widget shows latest questions from stackoverflow.com with a given tag(s).

![screenshot](./screenshot.png)

## Customization

It is possible to customize widget by providing a table with all or some of the following config parameters:

| Name | Default | Description |
|---|---|---|
| `icon`| `/.config/awesome/awesome-wm-widgets/stackoverflow-widget/so-icon.svg` | Path to the icon |
| `limit` | 5 | Number of items to show in the widget |
| `tagged` | awesome-wm | Tag, or comma-separated tags |
| `timeout` | 300 | How often in seconds the widget refreshes |

## Installation

1. Clone this repo (if not cloned yet) under **~/.config/awesome/**:

    ```bash
    git clone https://github.com/streetturtle/awesome-wm-widgets.git ~/.config/awesome/
    ```

1. Require widget at the top of the **rc.lua**:

    ```lua
    local stackoverflow_widget = require("awesome-wm-widgets.stackoverflow-widget.stackoverflow")
    ```

1. Add widget to the tasklist:

    ```lua
    s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            ...
            --default
            stackoverflow_widget(),
            --customized
            stackoverflow_widget({
                limit = 10
            })
            ...
    ```
    
