local awful = require("awful")

local async = require("async")
local command = require("command")
local debug_util = require("debug_util")

local enabled = true
local transparency_enabled = true
local opacity = 0.85
local pid = nil
local restarting = false

local compton_command = command.get_available_command({{command="compton"}})

local compton = {}

local function setup_config_file()
    local content =
        'backend = "glx";\n' ..
        'paint-on-overlay = true;\n' ..
        'vsync = "opengl-swc";\n'
    if transparency_enabled then
        content = content ..
            'inactive-opacity = ' .. tostring(opacity) .. ';\n' ..
            'focus-exclude = "! name~=\'\'";\n'
    end

    local filename = os.getenv("HOME") .. "/.config/compton.conf"
    local f = io.open(filename, "w")
    f:write(content)
    f:close()
end

local function reset_config()
    setup_config_file()
    if enabled and pid then
        restarting = true
        -- awful.spawn("kill -USR1 " .. tostring(pid))
        awful.spawn("kill " .. tostring(pid))
    end
end

local function start()
    if not compton_command then
        debug_util.log("Compton is not available")
        return
    end
    debug_util.log("Running compton")
    setup_config_file()
    async.run_command_continuously("compton",
            function() end,
            function(pid_) pid = pid_ end,
            function()
                if restarting then
                    restarting = false
                    if enabled then
                        start()
                    end
                    return true
                end
                return not enabled
            end)
end

local function set_enabled(value)
    if value == enabled then
        return
    end

    enabled = value

    if enabled then
        start()
    else
        awful.spawn("kill " .. tostring(pid))
    end
end

function compton.set_opacity(value)
    if value < 0.0 then
        value = 0.0
    end
    if value > 1.0 then
        value = 1.0
    end
    opacity = value
    reset_config()
end

function compton.increase_opacity(value)
    compton.set_opacity(opacity + value)
end

function compton.decrease_opacity(value)
    compton.set_opacity(opacity - value)
end

function compton.toggle_transparency()
    transparency_enabled = not transparency_enabled
    reset_config()
end

function compton.enable_transparency()
    transparency_enabled = true
    reset_config()
end

function compton.disable_transparency()
    transparency_enabled = false
    reset_config()
end

function compton.enable()
    set_enabled(true)
end

function compton.disable()
    set_enabled(false)
end

function compton.toggle()
    set_enabled(not enabled)
end

awesome.connect_signal("startup",
    function()
        if enabled then
            awful.spawn("killall compton")
            start()
        end
    end)

return compton
