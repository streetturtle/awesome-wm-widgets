local wibox = require("wibox")
local beautiful = require('beautiful')

local ICON_DIR = os.getenv("HOME") .. '/.config/awesome/awesome-wm-widgets/experiments/volume/icons/'

local widget = {}

function widget.get_widget()

    return wibox.widget {
        {
            id = "icon",
            image = ICON_DIR .. 'audio-volume-high-symbolic.svg',
            resize = true,
            widget = wibox.widget.imagebox,
        },
        max_value = 100,
        thickness = 2,
        start_angle = 4.71238898, -- 2pi*3/4
        forced_height = 18,
        forced_width = 18,
        bg = '#ffffff11',
        paddings = 2,
        widget = wibox.container.arcchart,
        set_volume_level = function(self, new_value)
            self.value = new_value
        end,
        mute = function(self)
            self.colors = {'#BF616A'}
        end,
        unmute = function(self)
            self.colors = {beautiful.fg_color}
        end
    }

end


return widget