# Brightness widget

![Brightness widget](./br-wid-1.png)

This widget represents current brightness level.

## Installation

Firstly you need to get the current brightness level. There are two options:

 - using `xbacklight` command (depending on your video card (I guess) it may or may not work)
 
    To check if it works install xbackligth and check if it works:
 
    ```bash
    sudo apt-get install xbacklight
    xbacklight -get
    ```

    If there is no output it means that it doesn't work, but there is a second option:

 - using `light` command
 
    Install it from this git repo: [github.com/haikarainen/light](https://github.com/haikarainen/light) and check if it works but running

    ```bash
    git clone https://github.com/haikarainen/light.git && \
    cd ./light && \
    sudo make && sudo make install \
    light -G
    49.18
    ```
Depending on the chosen option change `GET_BRIGHTNESS_CMD` variable in **brightness.lua**.

Then in **rc.lua** add the import on top of the file and then add widget to the wibox:

```lua
require("awesome-wm-widgets.brightness-widget.brightness")
...
-- Add widgets to the wibox
s.mywibox:setup {
...
{ -- Right widgets
...
brightness_widget
```

## Controls

In order to change brightness by shortcuts you can add them to the `globalkeys` table in the **rc.lua**:

```lua
awful.key({ modkey         }, ";", function () awful.spawn("light -A 5") end, {description = "increase brightness", group = "custom"}),
awful.key({ modkey, "Shift"}, ";", function () awful.spawn("light -U 5") end, {description = "decrease brightness", group = "custom"}),
```
On laptop you can use `XF86MonBrightnessUp` and `XF86MonBrightnessDown` keys.
