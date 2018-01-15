local awful = require("awful")
local gears = require("gears")

local async = require("async")
local Semaphore = require("Semaphore")

local locker = {}

local args = {}

local enable_command = "xautolock -enable"
local disable_command = "xautolock -disable"
local lock_command = "xautolock -locknow"

function locker.lock(callback)
    locker.callback = callback
    async.spawn_and_get_output(enable_command,
        function()
            local command
            async.spawn_and_get_output(lock_command,
                function()
                    if locker.prevent_idle:is_locked() then
                        awful.spawn(disable_command)
                    end
                end)
        end)
end

locker.prevent_idle = Semaphore(
        function()
            awful.spawn(disable_command)
        end,
        function()
            awful.spawn(enable_command)
        end)

function locker.run_callback()
    if locker.callback then
        locker.callback()
        locker.callback = nil
    end
end

local function initialize()
    async.spawn_and_get_output("pidof xautolock",
            function(pid_)
                local pid = tonumber(pid_)
                if pid then
                    gears.timer.start_new(0.5,
                            function()
                                initialize()
                                return false
                            end)
                else
                    async.run_command_continuously("xautolock"
                            .. " -locker ~/.config/awesome/lock-session"
                            .. " -time " .. tostring(args.lock_time)
                            .. " -killer 'xset dpms force off'"
                            .. " -killtime " .. tostring(args.blank_time))
                end
                return true
            end)
end

function locker.init(args_)
    args = args_
    awful.spawn("xautolock -exit")
    initialize()
end

return locker
