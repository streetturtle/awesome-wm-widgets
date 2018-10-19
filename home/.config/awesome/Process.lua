local awful = require("awful")
local gears = require("gears")

local async = require("async")
local D = require("debug_util")
local serialize = require("serialize")
local StateMachine = require("StateMachine")
local variables = require("variables")
local tables = require("tables")

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
    local self = setmetatable(gears.object{}, Process)
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
                should_be_running=false,
                running=false,
            },
            Starting={
                should_be_running=true,
                running=false,
            },
            Running={
                enter="start_ok_timer",
                exit="stop_ok_timer",
                should_be_running=true,
                running=true,
            },
            WaitForRestart={
                enter={"start_restart_timer", "increment_tries"},
                exit="stop_restart_timer",
                should_be_running=true,
                running=false,
            },
            WaitForStartBeforeStop={
                should_be_running=false,
                running=false,
            },
            Stopping={
                enter="start_stop_timer",
                exit="stop_stop_timer",
                should_be_running=false,
                running=true,
            },
            Restarting={
                enter="start_stop_timer",
                exit="stop_stop_timer",
                should_be_running=true,
                running=true,
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
                    to="WaitForRestart",
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
                    action={"print_giveup", "reset_tries"},
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
        D.log("Process " .. name .. " is already running as "
            .. tostring(pid) .. ". Restarting.")
        awful.spawn("kill " .. tostring(pid))
        self.state_machine:process_event("start")
    end

    self.was_running = false

    self.state_machine:connect_signal("state_changed",
        function()
            is_running = self:is_running()
            if is_running ~= self.was_running then
                if is_running then
                    self:emit_signal("started")
                else
                    self:emit_signal("stopped")
                end
                self.was_running = is_running
            end
        end)

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

function Process:should_be_running()
    return self.state_machine.states[self.state_machine.state].should_be_running
end

function Process:is_running()
    return self.state_machine.states[self.state_machine.state].running
end

local running_pids_file = variables.config_dir .. "/running_pids.json"

local function save_running_pids()
    serialize.save_to_file(running_pids_file, running_pids)
end

function actions.start(args)
    local state_machine = args.state_machine
    local self = state_machine.obj
    local command = self.command
    local command_name = tables.concatenate(command)

    D.log("Running command: " .. command_name)
    local pid = async.spawn_and_get_lines(command,
        function(line)
            self:emit_signal("line", line)
        end,
        function(code, log)
            D.log("Command stopped: " .. command_name)
            D.log(log.stderr)
            self.pid = nil
            running_pids[state_machine.name] = nil
            save_running_pids()
            args.state_machine:postpone_event("stopped")
            return true
        end,
        function()
            self:emit_signal("output_done")
        end)
    if pid and type(pid) == "number" then
        self.pid = pid
        running_pids[state_machine.name] = pid
        save_running_pids()
        state_machine:postpone_event("started")
    else
        D.log("Could not start command: " .. command_name)
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
    D.log("Failed to start command: "
        .. tables.concatenate(args.state_machine.obj.command))
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
