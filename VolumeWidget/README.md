## Volume widget
Simple and easy-to-install widget for Awesome Window Manager.

This widget represents the sound level: ![Volume Wiget](./volWid.png)

## Installation

- clone/copy volume.lua file and volume-icons folder to your `~/home/username/.config/awesome/` folder;

- change path to the icons in `volume.lua`:

```
widget:set_image("/home/<username>/.config/awesome/volume-icons/" .. volumeLevel .. ".png")
```

- include `volume.lua` and add volume widget to your wibox in rc.lua:
```
require("volume")
...
right_layout:add(volumeWidget)
```
