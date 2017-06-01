local gears = require("gears")
local awful = require("awful")
local xscreensaver = require('xscreensaver')

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
    call_systemctl("reboot")
end

local function hibernate()
    lock_and_call_systemctl("hibernate")
end

local function poweroff()
    call_systemctl("poweroff")
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
