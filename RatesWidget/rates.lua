local wibox = require("wibox")
local awful = require("awful")

rateWidget = wibox.widget.textbox()

-- DBus (Command are sent to Dbus, which prevents Awesome from freezу)
sleepTimerDbus = timer ({timeout = 1800})
sleepTimerDbus:connect_signal ("timeout", 
	function ()
		awful.util.spawn_with_shell("dbus-send --session --dest=org.naquadah.awesome.awful /com/console/rate com.console.rate.rateWidget string:$(python ~/.config/awesome/rates/rates.py)" )
	end)
sleepTimerDbus:start()
sleepTimerDbus:emit_signal("timeout")

dbus.request_name("session", "com.console.rate")
dbus.add_match("session", "interface='com.console.rate', member='rateWidget' " )
dbus.connect_signal("com.console.rate", 
	function (...)
		local data = {...}
		local dbustext = data[2]
		rateWidget:set_text(dbustext)
	end)

-- The notification popup which shows rates for other currencies
function showRatesPopup()   
    naughty.notify({
        title = "Rates",
        text = awful.util.pread("python ~/.config/awesome/rates/ratesPopup.py"), 
        icon = "/home/username/.config/awesome/rates/currency.png",
        icon_size = 100,
        timeout = 10, 
        width = 300,
        padding = 100,
        fg = "#ffffff",
        bg = "#333333aa",
    })
end

rateWidget:connect_signal("mouse::enter", function() showRatesPopup() end)