-------------------------------------------------
-- Logout widget for Awesome Window Manager
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/logout-widget

-- @author Pavel Makhov
-- @copyright 2020 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local gfs = require("gears.filesystem")
local wibox = require("wibox")
local gears = require("gears")

local ICON = '/usr/share/icons/Papirus-Light/32x32/apps/spotify-linux-48x48.svg'

local spotify_shell = awful.widget.prompt()

local w = wibox {
    bg = '#1e252c',
    border_width = 1,
    border_color = '#84bd00',
    max_widget_size = 500,
    ontop = true,
    height = 400,
    width = 250,
    shape = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, 3)
    end
}

w:setup {
    {
        {
            {
                image = ICON,
                widget = wibox.widget.imagebox,
                resize = false
            },
            id = 'icon',
            top = 9,
            left = 10,
            layout = wibox.container.margin
        },
        {
            layout = wibox.container.margin,
            left = 10,
            spotify_shell,
        },
        id = 'left',
        layout = wibox.layout.fixed.horizontal
    },
    {
        image  = '/usr/share/icons/Arc/actions/symbolic/system-shutdown-symbolic.svg',
        widget = wibox.widget.imagebox,
        resize = false,
        opacity = 0.2,
        set_hover = function(self, opacity)
            self.opacity = opacity
            self.image = '/usr/share/icons/Arc/actions/symbolic/system-shutdown-symbolic.svg'
        end

    },
    layout = wibox.layout.fixed.vertical
}

local function launch()
    w.visible = true

    awful.placement.top(w, { margins = {top = 40}, parent = awful.screen.focused()})
    awful.prompt.run{
        prompt = "<b>Spotify Shell</b>: ",
        bg_cursor = '#84bd00',
        textbox = spotify_shell.widget,
        history_path = gfs.get_dir('cache') .. '/spotify_history',
        exe_callback = function(input_text)
            if not input_text or #input_text == 0 then return end
            awful.spawn("sp " .. input_text)
        end,
        done_callback = function()
            w.visible = false
        end
    }
end

return {
    launch = launch
}
