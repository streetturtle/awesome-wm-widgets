local wibox = require("wibox")

local widget = {}

local ICON_DIR = os.getenv("HOME") .. '/.config/awesome/awesome-wm-widgets/volume-widget/icons/'

function widget.get_widget(widgets_args)
    local args = widgets_args or {}

    local icon_dir = args.icon_dir or ICON_DIR

    return wibox.widget {
        {
            id = "icon",
            resize = false,
            widget = wibox.widget.imagebox,
        },
        valign = 'center',
        layout = wibox.container.place,
        set_volume_level = function(self, new_value)
            local volume_icon_name
            local new_value_num = tonumber(new_value)
            if self.is_muted or new_value_num == 0 then
                volume_icon_name = 'audio-volume-muted-symbolic'
            else
                if (new_value_num <= 30) then
                    volume_icon_name="audio-volume-low-symbolic"
                elseif (new_value_num <= 70) then
                    volume_icon_name="audio-volume-medium-symbolic"
                else
                    volume_icon_name="audio-volume-high-symbolic"
                end
            end
            self:get_children_by_id('icon')[1]:set_image(icon_dir .. volume_icon_name .. '.svg')
        end,
        mute = function(self)
            self.is_muted = true
            self:get_children_by_id('icon')[1]:set_image(icon_dir .. 'audio-volume-muted-symbolic.svg')
        end,
        unmute = function(self)
            self.is_muted = false
        end
    }
end

return widget