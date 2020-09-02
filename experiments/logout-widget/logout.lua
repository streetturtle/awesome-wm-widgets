-------------------------------------------------
-- Logout widget for Awesome Window Manager
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/logout-widget

-- @author Pavel Makhov
-- @copyright 2020 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local capi = {keygrabber = keygrabber }
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local fancybuttons = require("awesome-buttons.awesome-buttons")


local HOME_DIR = os.getenv("HOME")
local WIDGET_DIR = HOME_DIR .. '/.config/awesome/awesome-wm-widgets/experiments/logout-widget'
local ICONS_DIR = WIDGET_DIR .. '/icons/'


local w = wibox {
    bg = beautiful.fg_normal,
    max_widget_size = 500,
    ontop = true,
    height = 200,
    width = 400,
    shape = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, 8)
    end
}

local action = wibox.widget {
    text = ' ',
    widget = wibox.widget.textbox
}


local function create_button(icon_name, action_name, color, onclick)

    local button = fancybuttons.with_icon{ type = 'basic', shape = 'circle', icon = ICONS_DIR .. icon_name, color = color, onclick = onclick }
    button:connect_signal("mouse::enter", function(c) action:set_text(action_name) end)
    button:connect_signal("mouse::leave", function(c) action:set_text(' ') end)
    return button
end

local function launch(args)

    local bg_color = args.bg_color or beautiful.bg_normal
    local accent_color = args.accent_color or beautiful.bg_focus
    local text_color = args.text_color or beautiful.fg_normal
    local phrases = args.phrases or {'Goodbye!'}

    local onlogout = args.onlogout or function () awesome.quit() end
    local onlock = args.onlock
    local onreboot = args.onreboot
    local onsuspend = args.onsuspend
    local onpoweroff = args.onpoweroff or function () awful.spawn.with_shell("shutdown now") end

    w:set_bg(bg_color)

    w:setup {
        {
            {
                markup = '<span color="'.. text_color .. '" size="20000">' .. phrases[ math.random( #phrases ) ] .. '</span>',
                align  = 'center',
                widget = wibox.widget.textbox
            },
            {
                {
                    create_button('log-out.svg', 'Log Out', accent_color, onlogout),
                    create_button('lock.svg', 'Lock', accent_color, onlock),
                    create_button('refresh-cw.svg', 'Reboot', accent_color, onreboot),
                    create_button('moon.svg', 'Suspend', accent_color, onsuspend),
                    create_button('power.svg', 'Power Off', accent_color, onpoweroff),
                    id = 'buttons',
                    spacing = 8,
                    layout = wibox.layout.fixed.horizontal
                },
                valigh = 'center',
                layout = wibox.container.place
            },
            {
                action,
                haligh = 'center',
                layout = wibox.container.place
            },
            spacing = 32,
            layout = wibox.layout.fixed.vertical
        },
        id = 'a',
        shape_border_width = 1,
        valigh = 'center',
        layout = wibox.container.place
    }

    w.visible = true

    awful.placement.centered(w)
    capi.keygrabber.run(function(_, key, event)
        if event == "release" then return end
        if key then
            capi.keygrabber.stop()
            w.visible = false
        end
    end)
end

return {
    launch = launch
}
