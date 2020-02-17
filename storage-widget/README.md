# Storage Widget

This widget shows disk usage. When clicked another widget appears with more detailed information. By default it monitors the "/" mount. It can be configured with a
list of mounts to monitor though only the first will show in the wibar. To have
multiple mounts displayed on the wibar simply define multiple `storage_widgets`
with different mounts as arguments.


```lua
  local storage_widget = require("awesome-wm-widgets.storage-widget.storage-widget")
  ...
  s.mywibox:setup {
      s.mytasklist, -- Middle widget
      { -- Right widgets
      storage_widget(), --default
      wibox.widget.textbox(':'),
      storage_widget({ mounts = { '/', '/mnt/musicj' } }), -- multiple mounts
  ...

```

## Installation

Please refer to the [installation](https://github.com/streetturtle/awesome-wm-widgets#installation) section of the repo.
