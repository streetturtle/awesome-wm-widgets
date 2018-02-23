local gears = require("gears")
local awful = require("awful")
local naughty = require("naughty")
local locker = require('locker')
local shutdown = require('shutdown')

local function call_systemctl(command)
    awful.spawn("systemctl " .. command)
end

local function lock_and_call_systemctl(command)
    locker.lock(function() call_systemctl(command) end)
end

local power = {}

function power.suspend()
    lock_and_call_systemctl("suspend")
end

function power.reboot()
    shutdown.clean_shutdown('Reboot', 30,
        function() call_systemctl("reboot") end)
end

function power.hibernate()
    lock_and_call_systemctl("hibernate")
end

function power.poweroff()
    shutdown.clean_shutdown('Power off', 30,
        function() call_systemctl("poweroff") end)
end

function power.quit()
    shutdown.clean_shutdown('Quit awesome', 30, awesome.quit)
end

function power.power_menu()
    local notification = nil
    local function call(f)
        return function()
            naughty.destroy(notification,
                    naughty.notificationClosedReason.dismissedByUser)
            f()
        end
    end

    notification = naughty.notify({
        title='Power',
        text='Choose action to take.',
        timeout=30,
        actions={
            ['power off']=call(power.poweroff),
            suspend=call(power.suspend),
            hibernate=call(power.hibernate),
            reboot=call(power.reboot),
            ['quit awesome']=call(power.quit),
            cancel=call(function() end),
        }
    })
end

return power
