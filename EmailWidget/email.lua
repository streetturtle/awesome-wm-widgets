local wibox = require("wibox")
local awful = require("awful")
local naughty = require("naughty")

function showEmailWidgetPopup()	
	local save_offset = offset
	local popuptext = "test"
	naughty.notify({
		title = "Unread emails",
		text = awful.util.pread("python /home/username/.config/awesome/getUnreadEmails.py"),
		timeout = 10, 
		width = 300,
		fg = "#ffffff",
		bg = "#333333aa",
		})
end

-- Icon which shows unread emails when hover
emailIcon = wibox.widget.imagebox()
emailIcon:set_image("/home/username/.config/awesome/mail.png")
emailIcon:connect_signal("mouse::enter", function() showEmailWidgetPopup() end)

dbus.request_name("session", "ru.console.df")
dbus.add_match("session", "interface='ru.console.df', member='fsValue' " )
dbus.connect_signal("ru.console.df", 
	function (...)
		local data = {...}
		local dbustext = data[2]
		emailCount:set_text(dbustext)
	end)

-- Counter which shows number of unread emails
emailCount = wibox.widget.textbox()

emailCountTimer = timer ({timeout = 5})
emailCountTimer:connect_signal ("timeout", 
	function ()
		awful.util.spawn_with_shell("dbus-send --session --dest=org.naquadah.awesome.awful /ru/console/df ru.console.df.fsValue string:$(python /home/username/.config/awesome/getUnreadEmailsNum.py)" )
	end)
emailCountTimer:start()
