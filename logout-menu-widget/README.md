# Logout Menu Widget

This widget shows a menu with options to log out from the current session, lock, reboot, suspend and power off the computer, similar to [logout-popup-widget](https://github.com/streetturtle/awesome-wm-widgets/tree/master/logout-popup-widget):

![demo](./logout-menu.gif)

## Installation

Clone this repo (if not cloned yet) under **./.config/awesome/**

```bash
cd ./.config/awesome/
git clone https://github.com/streetturtle/awesome-wm-widgets
```
Then add the widget to the wibar:

```lua
local logout_menu_widget = require("awesome-wm-widgets.logout-menu-widget.logout-menu")

s.mytasklist, -- Middle widget
    { -- Right widgets
        layout = wibox.layout.fixed.horizontal,
        ...
        -- default
        logout_menu_widget(),
        -- custom
        logout_menu_widget{
            font = 'Play 14',
            onlock = function() awful.spawn.with_shell('i3lock-fancy') end
        }
        ...
```

## Customization

It is possible to customize the widget by providing a table with all or some of the following config parameters:

| Name | Default | Description |
|---|---|---|
| `font` | `beautiful.font` | Font of the menu items |
| `onlogout` | `function() awesome.quit() end` | Function which is called when the logout item is clicked |
| `onlock` | `function() awful.spawn.with_shell("i3lock") end` | Function which is called when the lock item is clicked |
| `onreboot` | `function() awful.spawn.with_shell("reboot") end` | Function which is called when the reboot item is clicked |
| `onsuspend` | `function() awful.spawn.with_shell("systemctl suspend") end` | Function which is called when the suspend item is clicked |
| `onpoweroff` | `function() awful.spawn.with_shell("shutdown now") end` | Function which is called when the poweroff item is clicked |
