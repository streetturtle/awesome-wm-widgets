# word clock widget

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
local word_clock = require("awesome-wm-widgets.word-clock-widget.word-clock")
...
s.mytasklist, -- Middle widget
	{ -- Right widgets
    	layout = wibox.layout.fixed.horizontal,
		...
		word_clock(),		
	...
```

# Screenshots

```lua
 word_clock{
    font = 'Carter One 12',
    accent_color = '#ff79c6',
    main_color = '#8be9fd',
    is_human_readable = true,
}
```
![](./screenshots/halfpastthree_color.png)


```lua
word_clock{
    font = 'Carter One 12',
    is_human_readable = true,
}
```
![](./screenshots/twentythreepastnine.png)


```lua
word_clock{
    font = 'Carter One 12',
    is_human_readable = true,
    military_time = true
}
```
![](./screenshots/twentythreepasttwentyone.png)


```lua
word_clock{
    font = 'Carter One 12',
    accent_color = '#f00',
    main_color = '#0f0',
}
```
![](./screenshots/onetwentyseven.png)
