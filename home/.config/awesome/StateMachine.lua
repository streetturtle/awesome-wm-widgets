local tables = require("tables")
local gears = require("gears")
local D = require("debug_util")

local StateMachine = {}
StateMachine.__index = StateMachine

setmetatable(StateMachine, {
    __call = function(cls, ...)
        return cls.new(...)
    end
})

function log(self, severity, msg)
    if self.name then
        D.log(severity, self.name .. ": " .. msg)
    end
end

local function do_call(self, action, arg)
    if not self.actions[action] then
        log(self, D.error, "Action not found: " .. action)
        return
    end

    log(self, D.debug, "Executing action: " .. action)
    return self.actions[action](arg)
end

local function call(self, action, arg)
    if type(action) == "table" then
        for _, a in ipairs(action) do
            do_call(self, a, arg)
        end
    else
        return do_call(self, action, arg)
    end
end

function enter_state(self, state, arg)
    if state then
        log(self, D.debug, "Entering state: " .. state)
        self.state = state
        if self.states[state] and self.states[state].enter then
            call(self, self.states[state].enter, {
                state=state,
                state_machine=self,
                arg=arg})
        end
        self:emit_signal("state_changed", self.state)
    end
end

function leave_state(self, arg)
    if self.state then
        if self.states[self.state] and self.states[self.state].exit then
            call(self, self.states[self.state].exit, {
                state=state,
                state_machine=self,
                arg=arg})
        end
        log(self, D.debug, "Leaving state: " .. self.state)
        self.state = nil
    end
end

local function process_transition(self, event, transition, arg)
    if transition.guard and not call(self, transition.guard, {
        state=self.state,
        event=event,
        state_machine=self}) then
        log(self, D.debug, "Guard failed")
        return false
    end

    from_state = self.state
    if transition.to then
        leave_state(self)
    end

    if transition.action then
        call(self, transition.action, {
            event=event,
            state_machine=self,
            from=from_state,
            to=transition.to,
            arg=arg})
    end

    if transition.to then
        enter_state(self, transition.to)
    end

    return true
end

-- args:
-- states={<state1>={enter=..., exit=...},...}
-- transitions={<from>={<event>=<event_spec>, ...}, ...}
-- <event_spec>={to=..., action=..., guard=...}
-- <event_spec>={{to=..., action=..., guard=...}, ...}
-- actions={<name>=<action>, ...}
--
-- Enter/exit actions: action({state, state_machine, arg})
-- Actions: action({from, to, event, state_machine, arg})
-- Guards: guard({state, event, state_machine}) -> bool
function StateMachine.new(args)
    local self = setmetatable(gears.object{}, StateMachine)
    self.states = tables.get(args, "states")
    self.transitions = tables.get(args, "transitions")
    self.actions = args.actions
    self.name = args.name

    initial_state = tables.get(args, "initial", "")
    enter_state(self, initial_state)

    return self
end

function StateMachine:process_event(event, arg)
    if not self.state then
        log(self, D.error, "No state.")
        return
    end

    if not self.transitions[self.state]
            or not self.transitions[self.state][event] then
        log(self, D.error, "No transition from state " .. self.state
            .. " on event " .. event .. ".")
        return
    end

    log(self, D.debug, "Processing event: " .. self.state .. " -> " .. event)

    transition = self.transitions[self.state][event]

    if transition[1] then
        for _, t in ipairs(transition) do
            if process_transition(self, event, t, arg) then
                return
            end
        end
    else
        process_transition(self, event, transition, arg)
    end
end

function StateMachine:postpone_event(event, arg)
    gears.timer.delayed_call(function()
        self:process_event(event, arg)
    end)
end

return StateMachine
