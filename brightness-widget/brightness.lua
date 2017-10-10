local wibox = require("wibox")
local watch = require("awful.widget.watch")

--local get_brightness_cmd = "xbacklight -get"
local get_brightness_cmd = "light -G"
local path_to_icons = "/usr/share/icons/Arc/status/symbolic/"

local brightness_text = wibox.widget.textbox()
brightness_text:set_font('Play 9')

local brightness_icon = wibox.widget {
    {
    	image = path_to_icons .. "display-brightness-symbolic.svg",
    	resize = false,
        widget = wibox.widget.imagebox,
    },
    layout = wibox.container.margin(brightness_icon, 0, 0, 3)
}

function brightness_widget(show_percentage)
   local widget_contents = {brightness_icon}
   if show_percentage then
      table.insert(widget_contents, brightness_text)
   end
   widget_contents.layout = wibox.layout.fixed.horizontal
   return wibox.widget(widget_contents)
end

watch(
    get_brightness_cmd, 1,
    function(widget, stdout, stderr, exitreason, exitcode)
        local brightness_level = tonumber(string.format("%.0f", stdout))
        widget:set_text(" " .. brightness_level .. "%")
    end,
    brightness_text
)
