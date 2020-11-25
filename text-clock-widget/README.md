# Text clock widget

Widget displaying current time using words:

![screenshot](./screenshots/halfpastthree.png)

## Customization

It is possible to customize widget by providing a table with all or some of the following config parameters:

| Name | Default | Description |
|---|---|---|
| main_color | `beautiful.fg_normal` | Color of the word on odd position |
| accent_color | `beautiful.fg_urgent` | Color of the word on even position |
| font | `beautiful.font` | Font (`Play 20`) |
| is_human_readable | `false` | _nine fifteen_ or _fifteen past nine_ | 
| military_time | `false` | 12 or 24 time format |
| with_spaces | `false` | Separate words with spaces |

## Installation

Clone repo, include widget and use it in **rc.lua**:

```lua
local text_clock = require("awesome-wm-widgets.text-clock-widget.text-clock")
...
s.mytasklist, -- Middle widget
	{ -- Right widgets
    	layout = wibox.layout.fixed.horizontal,
		...
		text_clock(),		
	...
```

# Screenshots

```lua
 text_clock{
    font = 'Carter One 12',
    accent_color = '#ff79c6',
    main_color = '#8be9fd',
    is_human_readable = true,
}
```
![](./screenshots/halfpastthree_color.png)


```lua
text_clock{
    font = 'Carter One 12',
    is_human_readable = true,
}
```
![](./screenshots/twentythreepastnine.png)


```lua
text_clock{
    font = 'Carter One 12',
    is_human_readable = true,
    military_time = true
}
```
![](./screenshots/twentythreepasttwentyone.png)


