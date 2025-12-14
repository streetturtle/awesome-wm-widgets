---
layout: page
---
# ToDo Widget

This widget displays a list of todo items and allows marking item as done/undone, delete an item and create new ones:

![screenshot](../awesome-wm-widgets/assets/img/widgets/screenshots/todo-widget/todo.gif)

## Installation

Widget persists todo items as JSON, so in order to simplify JSON serialization/deserialization, download **json.lua** from this repository: https://github.com/rxi/json.lua under the `~/.config/awesome` folder. And don't forget to star the repo!

Then clone this repository under **~/.config/awesome/** and add the widget in **rc.lua**:

```lua
local todo_widget = require("awesome-wm-widgets.todo-widget.todo")
...
s.mytasklist, -- Middle widget
	{ -- Right widgets
    	layout = wibox.layout.fixed.horizontal,
		...
        -- default        
        todo_widget(),
		...      
```
Also note that widget uses [Arc Icons](https://github.com/horst3180/arc-icon-theme) and expects them to be installed under `/usr/share/icons/Arc/`.

## Theming

Widget uses your theme's colors. In case you want to have different colors, without changing your theme, please create an issue for it. I'll extract them as widget parameters.
