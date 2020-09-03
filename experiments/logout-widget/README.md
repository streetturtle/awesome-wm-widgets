# Logout widget

Widget which allows to perform lock, reboot, log out, power off and sleep actions. If can be called either by a shortcut, or by clicking on a widget in wibar.

![screenshot](./screenshot.gif)

# Installation

Clone repo (if not cloned yet) under ~/.config/awesome, then

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


## Phrase



    bg_color = args.bg_color or beautiful.bg_normal
    accent_color = args.accent_color or beautiful.bg_focus
    text_color = args.text_color or beautiful.fg_normal
    phrases = args.phrases or {'Goodbye!'}

    onlogout = args.onlogout or function () awesome.quit() end
    onlock = args.onlock
    onreboot = args.onreboot
    onsuspend = args.onsuspend or function () awful.spawn.with_shell("systemctl suspend") end
    onpoweroff = args.onpoweroff or function () awful.spawn.with_shell("shutdown now") end