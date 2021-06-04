# Logout Popup Widget

Widget which allows to perform lock, reboot, log out, power off and sleep actions. It can be called either by a shortcut, or by clicking on a widget in wibar.

<p align="center">
    <img src="https://github.com/streetturtle/awesome-wm-widgets/raw/master/logout-popup-widget/screenshot.gif" alt="screenshot">
</p>

When the widget is shown, following shortcuts can be used:
 - <kbd>Escape</kbd> - hide widget
 - <kbd>s</kbd> - shutdown
 - <kbd>r</kbd> - reboot
 - <kbd>u</kbd> - suspend
 - <kbd>k</kbd> - lock
 - <kbd>l</kbd> - log out

# Installation

Clone this (if not cloned yet) and the [awesome-buttons](https://github.com/streetturtle/awesome-buttons) repos under **./.config/awesome/**

```bash
cd ./.config/awesome/
git clone https://github.com/streetturtle/awesome-wm-widgets
git clone https://github.com/streetturtle/awesome-buttons
```
Then 

- to show by a shortcut - define a shortcut in `globalkeys`:

    ```lua
    local logout_popup = require("awesome-wm-widgets.logout-popup-widget.logout-popup")
    ...
    globalkeys = gears.table.join(
    ...
        awful.key({ modkey }, "l", function() logout_popup.launch() end, {description = "Show logout screen", group = "custom"}),
    ```

- to show by clicking on a widget in wibar - add widget to the wibar:

    ```lua
    local logout_popup = require("awesome-wm-widgets.logout-popup-widget.logout-popup")
    
    s.mytasklist, -- Middle widget
            { -- Right widgets
                layout = wibox.layout.fixed.horizontal,
                ...
                logout_popup.widget{},
                ...
    ```

# Customisation

| Name | Default | Description |
|---|---|---|
| `icon` | `power.svg` | If used as widget - the path to the widget's icon |
| `icon_size` | `40` | Size of the icon |
| `icon_margin` | `16` | Margin around the icon |
| `bg_color` |  `beautiful.bg_normal` | The color the background of the |
| `accent_color` | `beautiful.bg_focus` | The color of the buttons |
| `text_color` | `beautiful.fg_normal` | The color of text |
| `label_color` | `beautiful.fg_normal` | The color of the button's label |
| `phrases` | `{'Goodbye!'}` | The table with phrase(s) to show, if more than one provided, the phrase is chosen randomly. Leave empty (`{}`) to hide the phrase |
| `onlogout` | `function() awesome.quit() end` | Function which is called when the logout button is pressed |
| `onlock` | `function() awful.spawn.with_shell("systemctl suspend") end` | Function which is called when the lock button is pressed |
| `onreboot` | `function() awful.spawn.with_shell("reboot") end` | Function which is called when the reboot button is pressed |
| `onsuspend` | `function() awful.spawn.with_shell("systemctl suspend") end` | Function which is called when the suspend button is pressed |
| `onpoweroff` | `function() awful.spawn.with_shell("shutdown now") end` | Function which is called when the poweroff button is pressed |

Some color themes for inspiration:

![nord](./logout-nord.png)
![outrun](./logout-outrun.png)
![dark](./logout-dark.png)
![dracula](./logout-dracula.png)

```lua
logout.launch{
    bg_color = "#261447", accent_color = "#ff4365", text_color = '#f706cf', icon_size = 40, icon_margin = 16, -- outrun
    -- bg_color = "#0b0c10", accent_color = "#1f2833", text_color = '#66fce1', -- dark
    -- bg_color = "#3B4252", accent_color = "#88C0D0", text_color = '#D8DEE9', -- nord
    -- bg_color = "#282a36", accent_color = "#ff79c6", phrases = {}, -- dracula, no phrase
    phrases = {"exit(0)", "Don't forget to be awesome.", "Yippee ki yay!"},
}
```
