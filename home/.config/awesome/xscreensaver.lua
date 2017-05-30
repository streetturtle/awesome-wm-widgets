local awful = require("awful")
local naughty = require("naughty")

local async = require("async")
local debug_util = require("debug_util")

local function watch()
    async.run_command_continuously("xscreensaver-command -watch",
            function(line)
                debug_util.log("Got xscreensaver action: " .. line)
                if string.match(line, "^LOCK") then
                    awesome.emit_signal("xscreensaver::lock")
                elseif string.match(line, "^UNBLANK") then
                    awesome.emit_signal("xscreensaver::unblank")
                end
            end)
end

local function lock()
      awful.spawn("xscreensaver-command -lock")
end

async.spawn_and_get_output("killall xscreensaver",
        function()
            async.run_command_continuously("xscreensaver -no-splash")
            watch()
            return true
        end)

return {
    lock=lock,
}
