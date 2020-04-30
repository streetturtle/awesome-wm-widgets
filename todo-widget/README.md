# ToDo Widget

This widget displays a list of to do items and allows to mark item as done/undone, delete an item and create new ones:

![screenshot](./todo.gif)

# Installation

Widget persists todo items as a JSON, so in order to simplify JSON serialisation/deserialisation download a **json.lua** from this repository: https://github.com/rxi/json.lua under `~/.config/awesone` folder. And don't forget to star a repo :)

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

# Theming

Widget uses your theme's colors. In case you want to have different colors, without changing your theme, please create an issue for it. I'll extract them as a widget parameters.
