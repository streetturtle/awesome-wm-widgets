local awful = require("awful")
local gears = require("gears")

local async = require("async")
local debug_util = require("debug_util")
local serialize = require("serialize")
local StateMachine = require("StateMachine")
local variables = require("variables")

local actions = {}

local Process = {}
Process.__index = Process
setmetatable(Process, {
    __call = function(cls, ...)
        return cls.new(...)
    end
})

local timer_names = {"ok", "stop", "restart"}

local active_names = {}
local running_pids = {}

local function check_name(name)
    if active_names[name] then
        error(name .. " is already running")
    end
end

function Process.new(name, command)
    check_name(name)
    local self = setmetatable({}, Process)
    self.command = command
    self.pid = nil
    self.tries = 0
    self.state_machine = StateMachine({
        name=name,
        initial="Idle",
        actions=actions,
        states={
            Idle={
                enter="clear_name",
                exit="set_name",
            },
            Starting={
            },
            Running={
                enter="start_ok_timer",
                exit="stop_ok_timer",
            },
            WaitForRestart={
                enter={"start_restart_timer", "increment_tries"},
                exit="stop_restart_timer",
            },
            WaitForStartBeforeStop={
            },
            Stopping={
                enter="start_stop_timer",
                exit="stop_stop_timer",
            },
            Restarting={
                enter="start_stop_timer",
                exit="stop_stop_timer",
            },
        },
        transitions={
            Idle={
                start={
                    to="Starting",
                    action="start",
                },
                stop={},
                restart={
                    to="Starting",
                    action="start",
                },
            },
            Starting={
                start={},
                stop={
                    to="WaitForStartBeforeStop",
                },
                restart={
                    to="Starting",
                },
                started={
                    to="Running",
                },
                stopped={
                    to="WaitFroRestart",
                },
            },
            Running={
                start={},
                stop={
                    to="Stopping",
                    action="stop",
                },
                restart={
                    to="Restarting",
                    action="stop",
                },
                stopped={
                    to="WaitForRestart",
                },
                ok_timeout={
                    action="reset_tries",
                },
            },
            WaitForRestart={
                restart_timeout={
                    to="Starting",
                    action="start",
                },
                give_up={
                    to="Idle",
                    action="print_giveup",
                },
                start={},
                stop={
                    to="Idle",
                },
                restart={
                    to="Starting",
                    action={"start", "reset_tries"},
                },
            WaitForStartBeforeStop={
            },
                start={
                    to="Starting",
                },
                restart={
                    to="Starting",
                },
                stop={},
                stopped={
                    to="Idle",
                },
                started={
                    to="Stopping",
                    action="stop",
                },
            },
            Stopping={
                start={
                    to="Restarting",
                },
                restart={
                    to="Restarting",
                },
                stop={},
                stopped={
                    to="Idle",
                },
                stop_timeout={
                    to="Stopping",
                    action="kill",
                },
            },
            Restarting={
                start={},
                restart={},
                stop={
                    to="Stopping",
                },
                stopped={
                    to="Starting",
                    action="start",
                },
                stop_timeout={
                    to="Stopping",
                    action="kill",
                },
            },
        },
    })
    self.state_machine.obj = self

    self.timers = {}
    local function create_timer(name, args)
        local event_name = name .. "_timeout"
        args.callback = function()
            self.state_machine:process_event(event_name)
        end
        self.timers[name] = gears.timer(args)
    end

    create_timer("ok", {timeout=2, single_shot=true})
    create_timer("restart", {timeout=0.5, single_shot=true})
    create_timer("stop", {timeout=2, single_shot=false})

    local pid = running_pids[name]
    if pid then
        debug_util.log("Process " .. name .. " is already running as "
            .. tostring(pid) .. ". Restarting.")
        awful.spawn("kill " .. tostring(pid))
        self.state_machine:process_event("start")
    end

    return self
end

function Process:start()
    self.state_machine:process_event("start")
end

function Process:stop()
    self.state_machine:process_event("stop")
end

function Process:restart()
    self.state_machine:process_event("restart")
end

local running_pids_file = variables.config_dir .. "/running_pids.json"

local function save_running_pids()
    serialize.save_to_file(running_pids_file, running_pids)
end

function actions.start(args)
    local state_machine = args.state_machine
    local self = state_machine.obj
    local command = self.command

    debug_util.log("Running command: " .. command)
    local pid = async.spawn_and_get_lines(command, function() end,
            function()
                debug_util.log("Command stopped: " .. command)
                self.pid = nil
                running_pids[state_machine.name] = nil
                save_running_pids()
                args.state_machine:postpone_event("stopped")
                return true
            end)
    if pid and type(pid) == "number" then
        self.pid = pid
        running_pids[state_machine.name] = pid
        save_running_pids()
        state_machine:postpone_event("started")
    else
        debug_util.log("Could not start command: " .. command)
        state_machine:postpone_event("stopped")
    end
end

function actions.stop(args)
    awful.spawn("kill " .. tostring(args.state_machine.obj.pid))
end

function actions.kill(args)
    awful.spawn("kill -9 " .. tostring(args.state_machine.obj.pid))
end

function actions.reset_tries(args)
    args.state_machine.obj.tries = 0
end

function actions.increment_tries(args)
    local self = args.state_machine.obj
    self.tries = self.tries + 1
    if self.tries > 3 then
        args.state_machine:postpone_event("give_up")
    end
end

function actions.print_giveup(args)
    debug_util.log("Failed to start command: "
        .. args.state_machine.obj.command)
end

function actions.set_name(args)
    check_name(args.state_machine.name)
    active_names[args.state_machine.name] = true
end

function actions.clear_name(args)
    active_names[args.state_machine.name] = nil
end

for _, name in ipairs(timer_names) do
    local timer_name = name .. "_timer"
    actions["start_" .. timer_name] = function(args)
        args.state_machine.obj.timers[name]:start()
    end
    actions["stop_" .. timer_name] = function(args)
        args.state_machine.obj.timers[name]:stop()
    end
end

if gears.filesystem.file_readable(running_pids_file) then
    running_pids = serialize.load_from_file(running_pids_file)
end

return Process
