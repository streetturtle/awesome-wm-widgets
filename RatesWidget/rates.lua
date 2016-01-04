local wibox = require("wibox")
local awful = require("awful")

rateWidget = wibox.widget.textbox()

-- DBus (Command are sent to Dbus, which prevents Awesome from freezу)
sleepTimerDbus = timer ({timeout = 5})
sleepTimerDbus:connect_signal ("timeout", 
	function ()
		awful.util.spawn_with_shell("dbus-send --session --dest=org.naquadah.awesome.awful /com/console/rate com.console.rate.rateWidget string:$(python ~/.config/awesome/rates/rates.py)" )
	end)
sleepTimerDbus:start()

dbus.request_name("session", "com.console.rate")
dbus.add_match("session", "interface='com.console.rate', member='rateWidget' " )
dbus.connect_signal("com.console.rate", 
	function (...)
		local data = {...}
		local dbustext = data[2]
		rateWidget:set_text(dbustext)
	end)
