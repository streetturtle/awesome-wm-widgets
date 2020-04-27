package = "cpu-widget"
version = "0.0.1"
source = {
   url = "https://github.com/streetturtle/awesome-wm-widgets/tree/rocks/cpu-widget/cpu-widget-0.0.1.tar.gz"
}
description = {
   summary = "CPU widget for Awesome Window Manager",
   detailed = [[
    CPU widget for Awesome 
    Window Manager.
    ]],
   homepage = "https://github.com/streetturtle/awesome-wm-widgets/tree/master/cpu-widget",
   license = "MIT"
}
supported_platforms = {
   "linux"
}
dependencies = {
   "lua >= 5.2"
}
build = {
   type = "builtin",
   modules = {
      ["cpu-widget"] = "cpu-widget.lua"
   }
}