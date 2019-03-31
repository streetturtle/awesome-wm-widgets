# Run Shell

Run prompt which is put inside a widget:

![video](https://imgur.com/ohjAuCQ)

## Installation

1. Clone this repo under **~/.config/awesome/**:

    ```bash
    git clone https://github.com/streetturtle/awesome-wm-widgets.git ~/.config/awesome/
    ```

1. Require widget at the beginning of **rc.lua**:

    ```lua
    local run_shell = require("awesome-wm-widgets.run_shell.run_shell")
    ```

1. Use it (don't forget to comment out the default prompt):

    ```lua
    awful.key({modkey}, "r", function () run_shell.launch() end),
 
