# Github Contributions Widget

Shows the contribution graph, similar to the one on the github profile page:

![screenshot](./screenshot.jpg)

## Customization

It is possible to customize the widget by providing a table with all or some of the following config parameters:

| Name | Default | Description |
|---|---|---|
| `username` | 'streetturtle' | Username |
| `days` | `365` | Number of days in the past, more days - wider the widget |
| `empty_color` | `beautiful.bg_normal` | Color of the days with no contributions |
| `with_border` | `true` | Should the graph contains border or not |
| `margin_top` | `1` | Top margin |

Few more screenshots:

1000 days, with border:  
![screenshot1](./screenshot1.jpg)

365 days, no border:  
![screenshot2](./screenshot2.jpg)


## Installation

Clone/download repo under **~/.config/awesome** and use widget in **rc.lua**:

```lua
local github_contributions_widget = require("awesome-wm-widgets.github-contributions-widget.github-contributions-widget")
...
s.mytasklist, -- Middle widget
	{ -- Right widgets
    	layout = wibox.layout.fixed.horizontal,
		...
		-- default
        github_contributions_widget({username = '<your username>'}),
		...
```
