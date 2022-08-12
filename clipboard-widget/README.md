# Clipboard widget

A clipboard widget using the xclip utility

## Customization

It is possible to customize widget by providing a table with all or some of the following config parameters:

| Name | Default | Description |
|---|---|---|
| `font` | `beautiful.font` | Font name and size, like `Play 12` |
| `timeout`| `1` | The wait time between clipboard content checks |
| `margin` | `16` | Margin around clipboard items |
| `max_items` | 10 | Max number of items in the popup |
| `max_show_length` | 64 | Max number of characters to show in the popup per item |
| `max_peek_length` | 32 | Max number of characters to show instead of the widget name when showing clipboard contents |
| `maximum_popup_width` | 400 | Maximum width of the popup |
| `widget_name` | "Clip" | The displayed name of the widget |
| `unactive_item_dim` | 0.7 | How much to dim the unactive items (lower is more)|

## Installation

Install xclip

Then clone this repo under **~/.config/awesome/**:

```bash
git clone https://github.com/streetturtle/awesome-wm-widgets.git ~/.config/awesome/awesome-wm-widgets
```

Require widget at the beginning of **rc.lua**:

```lua
local clipboard_widget = require("awesome-wm-widgets.clipboard-widget.clipboard")
```

Add the widget to the tasklist:

```lua
s.mytasklist, -- Middle widget
    { -- Right widgets
        layout = wibox.layout.fixed.horizontal,
        ...
        -- default
        clipboard_widget({}),
        -- or customized
        clipboard_widget{
            font = 'monospace 12',
            max_items = '8',
            widget_name = 'Clippy',        
        }
    }
    ...
```
## Shortcuts

To easily see what's in your clipboard right now you can create a keybind that will show clipboard contents instead of the widget_name. You can customize it with max_peek_length

```lua
awful.key({ modkey }, "c", function() clipboard_widget:show_contents() end),
```
To control selection of items

```lua
    awful.key({ modkey }, ".", function() clipboard_widget:next_item() end,
    awful.key({ modkey }, ",", function() clipboard_widget:previous_item() end,
```
## Controls

Right-click an item => copy to clipboard

Left-click an item => remove from popup
