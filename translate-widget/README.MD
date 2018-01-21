# Translate Widget

![demo](./demo.gif)

This widget is based on the [Yandex.Translate API](https://tech.yandex.com/translate/).

## Installation

1. Get an [API key](https://translate.yandex.com/developers/keys) and paste it **secrets.lua**
1. Require widget and secrets in **rc.lua**:

    ```lua
    local secrets = require("awesome-wm-widgets.secrets")
    local translate = require("awesome-wm-widgets.translate-widget.translate")
    ```

1. Create a translate prompt (just under `mypromptbox`):

    ```lua
    s.mypromptbox = awful.widget.prompt()
    s.translateprompt = awful.widget.prompt()
    ```

1. Add it to the left widgets of the wibox, just after `mypromptbox`:

    ```lua
    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            mylauncher,
            s.mytaglist,
            s.mypromptbox,
            s.translateprompt,
        },
    ```

1. Add a shortcut to run this prompt (note that we pass an API key from secrets.lua in method call):

    ```lua
    awful.key({ modkey }, "c", function()
            awful.prompt.run {
                prompt = "trnslt: ",
                textbox = awful.screen.focused().translateprompt.widget,
                exe_callback = function(text)
                    translate.translate(text, secrets.translate_widget_api_key)
                end
            }
    ```

## Controls

 - <kbd>Mod4</kbd> + <kbd>c</kbd> - opens a translate prompt;
 - left click on the popup widget - copies the translation to the clipboard and closes widget;
 - right click on the popup widget - copies text to translate to the clipboard and closes widget.
