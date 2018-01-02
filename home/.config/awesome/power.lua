local gears = require("gears")
local awful = require("awful")
local xscreensaver = require('xscreensaver')
local shutdown = require('shutdown')

local function call_systemctl(command)
    awful.spawn("systemctl " .. command)
end

local session_locked = false

local function lock_and_call_systemctl(command)
    xscreensaver.lock()
    gears.timer.start_new(0.5,
            function()
                if not session_locked then
                    return true
                end
                call_systemctl(command)
                return false
            end)
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

awesome.connect_signal("xscreensaver::lock",
        function()
            session_locked = true
        end)

awesome.connect_signal("xscreensaver::unblank",
        function()
            session_locked = false
        end)

return {
    suspend=suspend,
    reboot=reboot,
    hibernate=hibernate,
    poweroff=poweroff,
}
