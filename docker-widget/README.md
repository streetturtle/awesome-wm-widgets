# Docker Widget

The widget allows to manage docker containers, namely start/stop/pause/unpause:

<p align="center">
    <img src="https://github.com/streetturtle/awesome-wm-widgets/raw/master/docker-widget/docker.gif"/>
</p>

## Customization

It is possible to customize widget by providing a table with all or some of the following config parameters:

| Name | Default | Description |
|---|---|---|
| `icon` | `./docker-widget/icons/docker.svg` | Path to the icon |
| `number_of_containers` | `-1` | Number of last created containers to show |

## Installation

Clone the repo under **~/.config/awesome/** and add widget in **rc.lua**:

```lua
local docker_widget = require("awesome-wm-widgets.docker-widget.docker")
...
s.mytasklist, -- Middle widget
	{ -- Right widgets
    	layout = wibox.layout.fixed.horizontal,
        ...
        -- default
        docker_widget(),
        -- customized
        github_activity_widget{
            number_of_containers = 5
        },
```
