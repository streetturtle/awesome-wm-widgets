----------------------------
-- Notification widget
--
-- IMPORTANT: IT ONLY WORKS WITH THE AWESOME-GIT VERSION!!!
-- @author TornaxO7
-- @copyright TornaxO7
----------------------------

------ Awesome Library -----
local beautiful = require("beautiful")
local awful = require("awful")
local naughty = require("naughty")
local gears = require("gears")
local wibox = require("wibox")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi
----------------------------

beautiful.notification_bg = beautiful.bg_normal
beautiful.notification_fg = "#5B8234"
beautiful.notification_border_color = "#93a1a1"

naughty.notification.font = "Liberation Sans Bold 13"
naughty.notification.screen = 1
naughty.notification.border_width = dpi(5)
naughty.notification.width = dpi(500)
naughty.notification.timeout = 3

naughty.notification.icon_size = dpi(150)
local icon_size = dpi(150)

----- Widget Templates -----
local default_template = {
	{
		{
			{ ----- Icon -----
				forced_width = icon_size,
				forced_height = icon_size,

				widget = naughty.widget.icon
			},				
			{
				{
					{ ---- Title -----
						naughty.widget.title,

						valign = "center",
						halign = "center",

						widget = wibox.container.place
					},

					{ ----- Body/Message -----
						naughty.widget.message,

						valign = "top",
						align = "center",

						widget = wibox.container.place
					},

					layout = wibox.layout.align.vertical,
					expand = "outside",
					},

				margins = dpi(10),
				widget = wibox.container.margin,
			},
			layout = wibox.layout.align.horizontal,
		},

		margins = dpi(10),
		widget = wibox.container.margin
	},
	----- To let the text wrap ------
	strategy = "max",
	widget   = wibox.container.constraint,
}

local template_without_icon = {
	{
	
		{
			{ ----- Title -----
				naughty.widget.title,

				valign = "center",
				halign = "center",

				widget = wibox.container.place
			},
			{ ----- Body/Message -----
				naughty.widget.message,
		
				valign = "top",
				align = "center",
		
				widget = wibox.container.place
			},
			layout = wibox.layout.fixed.vertical,
		},
		----- The space between border and text -----
		margins = dpi(10),
		widget = wibox.container.margin
	},

	----- To let the text wrap ------
	strategy = "max",
	widget   = wibox.container.constraint,
}

naughty.connect_signal("request::display", function(notification)

	-- Set the markup of the title
	notification.title = '<span underline="low">' .. notification.title .. '</span>'

	notification.timeout = 3
    notification.resident = false

    -- Only if there's an icon: Add the icon-widget
    naughty.layout.box {
        notification = notification,
        border_width = dpi(5),
        screen = 1,
        widget_template = notification.icon and default_template or
          template_without_icon,
    }
end)
