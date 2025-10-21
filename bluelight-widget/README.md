
# Blue Light Filter Widget

This widget provides a simple way to toggle a blue light filter using [Redshift](https://github.com/jonls/redshift). It offers an easy mechanism to switch between day and night modes, reducing eye strain during late-night computer use.

| Day Mode | Night Mode |
|----------|------------|
|![Day Mode](day.png) | ![Night Mode](night.png) |

(I couldn't capture the effect itself)

I usually use every widget with my custom (kinda janky) [wrapper widget](https://github.com/VMatt013/MySetup/blob/Debian/.config/awesome/widgets/margin.lua) to make them look cleaner and more unified.


**With wrapper**

![With wrapper](with_wrapper.png)


## Installation

Clone this repository then add the widget to your wibar:

```lua
local bluelight_widget = require("awesome-wm-widgets.bluelight-widget")
local margin = require("awesome-wm-widgets.margin") -- In case you use my wrapper

s.mytasklist, -- Middle widget
    { -- Right widgets
        layout = wibox.layout.fixed.horizontal,
        ...
        bluelight_widget(), -- Add the widget here
        margin(bluelight_widget(), true), -- Add the widget with my wrapper
        bluelight_widget({night_args = {"-O", "3500", "-P", "-g", "0.75"}}), -- Pass arguments in string or table of strings
        ...
    }
```

## Usage

- Click the widget to toggle between **Day Mode** and **Night Mode**.
  - **Day Mode:** Disables the blue light filter.
  - **Night Mode:** Activates the blue light filter with a warm color temperature.

## Customization

You can pass arguments to the bluelight method. The following arguments are avaliable:

| Name       | Default                                | Description                                                |
|------------|----------------------------------------|------------------------------------------------------------|
| `cmd`      | ```redshift```                            | Command to run Redshift.                                   |
| `night_args`| ```-O 2500 -g 0.75 -P```            | Command options for activating Night Mode.                 |
| `day_args`  | ```-x```                                  | Command options for activating Day Mode.                   |
| `night_icon` | ```awesome-wm-widgets/bluelight-widget/moon.svg```  | Image to show when Night Mode is activated. |
| `day_icon` | ```awesome-wm-widgets/bluelight-widget/sun.svg```  | Image to show when Day Mode is activated |
| `auto` | false | Automatically change between modes based on location (see [the wiki](https://wiki.archlinux.org/title/Redshift)) |

## Dependencies

- [Redshift](https://github.com/jonls/redshift): Make sure Redshift is installed on your system.
