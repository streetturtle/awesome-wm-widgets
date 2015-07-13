## Volume widget
Simple and easy-to-install widget for Awesome Window Manager.

This widget represents the sound level: ![Volume Wiget](./volWid.png)

## Installation

- clone/copy volume.lua file and volume-icons folder to your `~/home/username/.config/awesome/` folder;

- include `volume.lua` and add volume widget to your wibox in rc.lua:
```
require("volume")
...
right_layout:add(volumeWidget)
```
