# Github Contributions Widget

The widget is inspired by the https://github-contributions.now.sh/ and relies on it's API. 

It shows the contribution graph, similar to the one on the github profile page: ![screenshot](./screenshots/screenshot.jpg)

You might wonder what could be the reason to have your github's contributions in front of you all day long? The more you contribute, the nicer widget looks! Check out [Thomashighbaugh](https://github.com/Thomashighbaugh)'s graph:

![](./screenshots/Thomashighbaugh.png)

## Customization

It is possible to customize the widget by providing a table with all or some of the following config parameters:

| Name | Default | Description |
|---|---|---|
| `username` | `streetturtle` | GitHub username |
| `days` | `365` | Number of days in the past, more days - wider the widget |
| `color_of_empty_cells` | Theme's default | Color of the days with no contributions |
| `with_border` | `true` | Should the graph contains border or not |
| `margin_top` | `1` | Top margin |
| `theme` | `standard` | Color theme of the graph, see below |

_Note:_ widget height is 21px (7 rows of 3x3 cells). So it would look nice on the wibar of 22-24px height.

### Themes

Following themes are available:

| Theme name | Preview |
|---|---|
| standard | ![standard](./screenshots/standard.png) |
| classic | ![classic](./screenshots/classic.png) |
| teal | ![teal](./screenshots/teal.png) |
| leftpad | ![leftpad](./screenshots/leftpad.png) |
| dracula | ![dracula](./screenshots/dracula.png) |
| pink | ![pink](./screenshots/pink.png) |

To add a new theme, simply add a new entry in `themes` table (themes.lua) with the colors of your theme.

### Screenshots

1000 days, with border:  
![screenshot1](./screenshots/screenshot1.jpg)

365 days, no border:  
![screenshot2](./screenshots/screenshot2.jpg)

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
