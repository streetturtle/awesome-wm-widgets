# Docker Widget

[![GitHub issues by-label](https://img.shields.io/github/issues-raw/streetturtle/awesome-wm-widgets/docker)](https://github.com/streetturtle/awesome-wm-widgets/labels/docker)
![Twitter URL](https://img.shields.io/twitter/url?url=https%3A%2F%2Fgithub.com%2Fstreetturtle%2Fawesome-wm-widgets%2Fedit%2Fmaster%2Fdocker-widget)

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
        docker_widget{
            number_of_containers = 5
        },
```
