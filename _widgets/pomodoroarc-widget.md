---
layout: page
---
# Pomodoro Widget

**Note:** This widget is under construction.

## Installation

### Dependencies

This widget is based on [@jsspencer](https://github.com/jsspencer)'s [pomo](https://github.com/jsspencer/pomo) - a simple pomodoro timer.

First install/clone it anywhere you like, then either
 - in the widget's code provide path to the pomo.sh, or
 - make a soft link in /usr/local/bin/ to it, e.g.:
 ```bash
 sudo ln -sf /opt/pomodoro/pomo.sh /usr/local/bin/pomo
 ``` 

Note that by default widget's code expects the second way and simply calls `pomo`.

### Enabling the widget

Add the widget to `rc.lua`:

```lua
--- Create the pomodoro widget
local pomo_widget = require('awesome-wm-widgets.pomodoroarc-widget.pomodoroarc')

--- Add the widget to the tasklist
s.mytasklist, -- Middle widget
    { -- Right widgets
        layout = wibox.layout.fixed.horizontal,
        ...
        pomo_widget,
        ...
```

## Usage

Left clicking ("mouse button 1") on the pomodoro widget starts the timer. Middle click ("mouse button 2") pauses and unpauses the timer. Right click ("mouse button 3") stops the timer.

Note that a left click will *always* restart the timer from scratch. Remember to middle click to unpause.

The circular pomodoro widget will give an approximate indication of how much time is remaining, hovering over the widget will display the exact remaining time.

The duration (in minutes) of work and breaks can be configured in the pomo.sh script, or by setting environment variables POMO_WORK_TIME and POMO_BREAK_TIME.

