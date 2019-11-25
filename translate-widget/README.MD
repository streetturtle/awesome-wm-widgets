# Translate Widget

This widget allows quickly translate words or phrases without opening a browser - just using Awesome. To provide direction of the translation add the 2 letters code of the source and target languages at the end of the phrase, for example _hello enfr_ will translate _hello_ from English to French. This widget is based on [Yandex.Translate API](https://tech.yandex.com/translate/).

![demo](./demo.gif)

## Controls

 - <kbd>Mod4</kbd> + <kbd>c</kbd> - opens a translate prompt;
 - left click on the popup widget - copies the translation to the clipboard and closes widget;
 - right click on the popup widget - copies text to translate to the clipboard and closes widget.

## Installation

1. Clone repo under **~/.config/awesome/**
1. Get an [API key](https://translate.yandex.com/developers/keys)
1. Require widget in **rc.lua**:

    ```lua
    local translate = require("awesome-wm-widgets.translate-widget.translate")
    ```

1. Add a shortcut to run translate prompt:

    ```lua
    awful.key({ modkey }, "c", 
        function() translate.show_translate_prompt('<api-key>') end, 
        { description = "run translate prompt", group = "launcher" }),
    ```

