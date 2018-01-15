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

local function suspend()
    lock_and_call_systemctl("suspend")
end

local function reboot()
    shutdown.clean_shutdown('Reboot', 30,
        function() call_systemctl("reboot") end)
end

local function hibernate()
    lock_and_call_systemctl("hibernate")
end

local function poweroff()
    shutdown.clean_shutdown('Power off', 30,
        function() call_systemctl("poweroff") end)
end

local function quit()
    shutdown.clean_shutdown('Quit awesome', 30, awesome.quit)
end

local function power_menu()
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
            ['power off']=call(poweroff),
            suspend=call(suspend),
            hibernate=call(hibernate),
            reboot=call(reboot),
            ['quit awesome']=call(quit),
            cancel=call(function() end),
        }
    })
end

return {
    suspend=suspend,
    reboot=reboot,
    hibernate=hibernate,
    poweroff=poweroff,
    quit=quit,
    power_menu=power_menu,
}
