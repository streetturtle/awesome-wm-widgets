# Logout widget

# Installation

Clone repo (if not cloned yet) under ~/.config/awesome, then

```lua
local logout = require("awesome-wm-widgets.experiments.logout-widget.logout")

    -- define a shorcut in globalkey
    awful.key({ modkey }, "l", function() logout.launch() end, {description = "Show logout screen", group = "custom"}),
```

# Customisation

