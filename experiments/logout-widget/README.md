# Logout widget

Widget which allows to perform lock, reboot, log out, power off and sleep actions. If can be called either by a shortcut, or by clicking on a widget in wibar.

![screenshot](./screenshot.gif)

# Installation

Clone this (if not cloned yet) and the Awesome-buttons repos under **./.config/awesome/**

```bash
cd ./.config/awesome/
git clone https://github.com/streetturtle/awesome-wm-widgets
git clone https://github.com/streetturtle/awesome-buttons
```
Then 

- to show by shortcut:

    ```lua
    local logout = require("awesome-wm-widgets.experiments.logout-widget.logout")
    ...
    globalkeys = gears.table.join(
    ...
        -- define a shorcut in globalkey
        awful.key({ modkey }, "l", function() logout.launch() end, {description = "Show logout screen", group = "custom"}),
    ```

- to show by clicking on a widget in wibar:

    ```lua
    local logout = require("awesome-wm-widgets.experiments.logout-widget.logout")
    
    s.mytasklist, -- Middle widget
            { -- Right widgets
                layout = wibox.layout.fixed.horizontal,
                ...
                logout.widget{
                    bg_color = "#000000",
                    accent_color = "#888888",
                    text_color = '#ffffff',
                    phrases = {'Yippee ki yay!', 'Hasta la vista, baby', 'See you later, alligator!', 'After a while, crocodile.'},
                    onlogout = function() naughty.notify{text = "Logged out!"} end
                },
                ...
    ```

# Customisation


| Name | Default | Description |
|---|---|---|
| `bg_color` |  `beautiful.bg_normal` | The color the background of the |
| `accent_color` |  `beautiful.bg_focus` | The color of the buttons |
| `text_color` |  `beautiful.fg_normal` | The color of text |
| `phrases` |  `{'Goodbye!'}` | The table with phrase(s) to show, if more than one provided, the phrase is chosen randomly |
| `onlogout` | `function() awesome.quit() end` | Function which is called when the logout button is pressed |
| `onlock` |  | Function which is called when the lock button is pressed |
| `onreboot` |  | Function which is called when the reboot button is pressed |
| `onsuspend` | `function() awful.spawn.with_shell("systemctl suspend") end` | Function which is called when the suspend button is pressed |
| `onpoweroff` | `function() awful.spawn.with_shell("shutdown now") end` | Function which is called when the poweroff button is pressed |

