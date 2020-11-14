local wibox = require("wibox")

local widget = {}

local WIDGET_DIR = os.getenv("HOME") .. '/.config/awesome/awesome-wm-widgets/experiments/volume/icons/'

function widget.get_widget()

    return wibox.widget {
        {
            {
                id = "icon",
                resize = false,
                widget = wibox.widget.imagebox,
            },
            valign = 'center',
            layout = wibox.container.place
        },
        {
            id = 'txt',
            widget = wibox.widget.textbox
        },
        layout = wibox.layout.fixed.horizontal,
        is_muted = true,
        set_volume_level = function(self, new_value)
            self:get_children_by_id('txt')[1]:set_text(new_value)
            local volume_icon_name = ''
            if self.is_muted then
                volume_icon_name = 'audio-volume-muted-symbolic.svg'
            else
                local new_value_num = tonumber(new_value)
                if (new_value_num >= 0 and new_value_num < 33) then
                    volume_icon_name="audio-volume-low-symbolic"
                elseif (new_value_num < 66) then
                    volume_icon_name="audio-volume-medium-symbolic"
                else
                    volume_icon_name="audio-volume-high-symbolic"
                end
            end
            self:get_children_by_id('icon')[1]:set_image(WIDGET_DIR .. volume_icon_name .. '.svg')
        end,
        mute = function(self)
            self.is_muted = true
            self:get_children_by_id('icon')[1]:set_image(WIDGET_DIR .. 'audio-volume-muted-symbolic.svg') 
        end,
        unmute = function(self)
            self.is_muted = false
        end,

    }

end


return widget