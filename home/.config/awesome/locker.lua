local awful = require("awful")
local gears = require("gears")

local async = require("async")
local Semaphore = require("Semaphore")

local locker = {}

local args = {}

local enable_command = "xautolock -enable"
local disable_command = "xautolock -disable"
local lock_command = "xautolock -locknow"
local locked = false
local disabled = false

local function do_lock()
    gears.timer.start_new(1,
            function()
                if locked then
                    return false
                end
                awful.spawn(lock_command)
                return true
            end)
end

function locker.lock(callback)
    locker.callback = callback
    if disabled then
        awful.spawn(enable_command)
        do_lock()
    else
        awful.spawn(lock_command)
    end
end

locker.prevent_idle = Semaphore(
        function()
            disabled = true
            awful.spawn(disable_command)
        end,
        function()
            disabled = false
            awful.spawn(enable_command)
        end)

function locker._run_callback()
    locked = true
    if locker.callback then
        locker.callback()
        locker.callback = nil
    end
end

function locker._on_lock_finished()
    locked = false
    if locker.prevent_idle:is_locked() then
        awful.spawn(disable_command)
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
    awful.spawn("xset dpms 0 0 0")
    async.spawn_and_get_output("xautolock -exit", initialize)
end

return locker
