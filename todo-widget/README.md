# ToDo Widget (in progress)

This widgets displays a list of to do items and allows to mark item as done, delete item and create new ones:

![screenshot](./todo.gif)

# Installation

Clone repo under **~/.config/awesome/** and add the widget in **rc.lua**:

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