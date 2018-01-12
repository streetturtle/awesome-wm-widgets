local awful = require("awful")
local gears = require("gears")

local async = require("async")
local debug_util = require("debug_util")
local dbus_ = require("dbus_")

local watch_pid = nil
local locked = false

local prevent_idle_counter = 0
local inhibitor = nil
local prevent_idle_timer = gears.timer({
    timeout=10,
    callback=function()
      awful.spawn("xscreensaver-command -deactivate")
    end})

local function update_prevent_idle()
    if prevent_idle_counter > 0 and not locked then
        prevent_idle_timer:start()
        if not inhibitor then
            inhibitor = dbus_.inhibit(
                    "idle", "Disbale screen power management", "block")
        end
    else
        prevent_idle_timer:stop()
        if inhibitor then
            dbus_.stop_inhibit(inhibitor)
            inhibitor = nil
        end
    end
end

local function watch()
    async.run_command_continuously("xscreensaver-command -watch",
            function(line)
                debug_util.log("Got xscreensaver action: " .. line)
                if string.match(line, "^LOCK") then
                    locked = true
                    update_prevent_idle()
                    awesome.emit_signal("xscreensaver::lock")
                elseif string.match(line, "^UNBLANK") then
                    locked = false
                    update_prevent_idle()
                    awesome.emit_signal("xscreensaver::unblank")
                end
            end,
            function(pid)
                watch_pid = pid
            end)
end

local function lock()
      awful.spawn("xscreensaver-command -lock")
end

local function prevent_idle()
    prevent_idle_counter = prevent_idle_counter + 1
    update_prevent_idle()
end

local function allow_idle()
    if prevent_idle_counter > 0 then
        prevent_idle_counter = prevent_idle_counter - 1
        update_prevent_idle()
    end
end

async.spawn_and_get_output("killall xscreensaver",
        function()
            async.run_command_continuously("xscreensaver -no-splash")
            watch()
            return true
        end)

awesome.connect_signal("exit",
        function()
            if watch_pid then
                awful.spawn("kill " .. watch_pid)
            end
        end)

return {
    lock=lock,
    prevent_idle=prevent_idle,
    allow_idle=allow_idle,
}
