local awful = require("awful")
local gears = require("gears")

local async = require("async")
local Semaphore = require("Semaphore")
local debug_util = require("debug_util")
local StateMachine = require("StateMachine")

local locker = {}

local args = {}
local callbacks = {}

local enable_commands = {"xautolock -enable"}
local disable_commands = {"xautolock -disable"}
local disable_screensaver_commands = {"xset -dpms", "xset s off"}
local lock_commands = {"xautolock -locknow"}
local locked = false
local disabled = false

local actions = {}
local state_machine = nil

local function reset_state_machine()
    state_machine = StateMachine({
        name="Locker",
        initial="Start",
        actions=actions,
        states={
            Start={
            },
            Enabled={
            },
            Disabled={
                enter="disable",
                exit="enable",
            },
            Locking={
                exit="stop_timer",
            },
            Locked={
                enter="call_callbacks",
                exit="disable_screensaver",
            },
        },
        transitions={
            Start={
                init={
                    {
                        to="Enabled",
                        guard="is_enabled"
                    },
                    {
                        to="Disabled",
                        guard="is_disabled"
                    },
                },
                lock={
                    action="print_not_running",
                },
                enable={},
                disable={},
            },
            Enabled={
                lock={
                    to="Locking",
                    action={"lock", "add_callback", "start_timer"},
                },
                locked={
                    to="Locked",
                },
                disable={
                    to="Disabled",
                },
            },
            Disabled={
                lock={
                    to="Locking",
                    action={"start_timer", "add_callback"},
                },
                enable={
                    to="Enabled",
                },
            },
            Locking={
                lock={
                    action="add_callback"
                },
                timeout={
                    action="lock",
                },
                locked={
                    to="Locked",
                },
            },
            Locked={
                lock={
                    action="call_callback",
                },
                unlocked={
                    {
                        to="Enabled",
                        guard="is_enabled"
                    },
                    {
                        to="Disabled",
                        guard="is_disabled"
                    },
                },
            },
        },
    })
end

local timer = gears.timer({
    timeout=1, autostart=false,
    callback=function() state_machine:process_event("timeout") end})

locker.prevent_idle = Semaphore(
        function()
            state_machine:process_event("disable")
        end,
        function()
            state_machine:process_event("enable")
        end)

function actions.add_callback(args)
    if args.arg then
        debug_util.log("Has callback")
        table.insert(callbacks, args.arg)
    else
        debug_util.log("No callback")
    end
end

function actions.call_callbacks(args)
    local callbacks_local = callbacks
    callbacks = {}

    debug_util.log("Number of callbacks: " .. tostring(#callbacks_local))
    for _, callback in ipairs(callbacks_local) do
        async.safe_call(callback)
    end
end

function actions.call_callback(args)
    async.safe_call(args.arg)
end

function actions.lock()
    async.run_commands(lock_commands)
end

function actions.start_timer()
    timer:start()
end

function actions.stop_timer()
    timer:stop()
end

function actions.enable()
    async.run_commands(enable_commands)
end

function actions.disable()
    async.run_commands(disable_commands)
end

function actions.disable_screensaver()
    async.run_commands(disable_screensaver_commands)
end

function actions.print_not_running()
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Locker",
                     text = "Locker is not running." })
end

function actions.is_enabled()
    return not locker.prevent_idle:is_locked()
end

function actions.is_disabled()
    return locker.prevent_idle:is_locked()
end

function locker.lock(callback)
    state_machine:process_event("lock", callback)
end

function locker._run_callback()
    state_machine:process_event("locked")
end

function locker._on_lock_finished()
    state_machine:process_event("unlocked")
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
                            .. " -killtime " .. tostring(args.blank_time)
                            .. " -notifier 'xset s activate'"
                            .. " -notify " .. tostring(args.notify_time),
                            function() end,
                            function()
                                state_machine:process_event("init")
                            end,
                            function()
                                reset_state_machine()
                            end)
                end
                return true
            end)
    return true
end

function locker.init(args_)
    args = args_
    awful.spawn("xset dpms 0 0 0")
    async.spawn_and_get_output("xautolock -exit", initialize)
end

reset_state_machine()

return locker
