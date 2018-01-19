in progress...

# Translate Widget

This widget is using the [Yandex.Translate API](https://tech.yandex.com/translate/).

## Installation

1. Get an [API key](https://translate.yandex.com/developers/keys)
1.

Create a translate prompt:

```lua
s.translateprompt = awful.widget.prompt()
```

Add it to the left widgets of the wibox, just after `mypromptbox`:

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

Add a shortcut to run this prompt:

```lua
awful.key({ modkey }, "c", function()
        awful.prompt.run {
            prompt = "trnslt: ",
            textbox = awful.screen.focused().translateprompt.widget,
            exe_callback = function(text)
                translate.translate(text)
            end
        }
```

## Controls

 - <kbd>Mod4</kbd> + <kbd>c</kbd> - opens a translate prompt;
 - left click on the popup widget - copies the translation to the clipboard and closes widget;
 - right click on the popup widget - copies text to translate to the clipboard and closes widget.
