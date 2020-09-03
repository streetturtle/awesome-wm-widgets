# Logout widget

# Installation

Clone repo (if not cloned yet) under ~/.config/awesome, then


- to show by shortcut:

    ```lua
    local logout = require("awesome-wm-widgets.experiments.logout-widget.logout")

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

You can provide a phrase which appears on the widget. 
