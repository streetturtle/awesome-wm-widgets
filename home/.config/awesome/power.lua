local gears = require("gears")
local awful = require("awful")
local naughty = require("naughty")
local locker = require('locker')
local shutdown = require('shutdown')
local command = require('command')
local dbus_ = require("dbus_")
local debug_util = require("debug_util")

local commands = {}

local function call_power_command(name)
    local command = commands[name]
    if command then
        debug_util.log("Calling command: " .. command)
        awful.spawn(command)
    else
        local message = "No command found for " .. name
        debug_util.log(message)
        naughty.notify({preset=naughty.config.presets.critical, text=message})
    end
end

local function lock_and_call_power_command(command)
    locker.lock(function() call_power_command(command) end)
end

local power = {}

function power.suspend()
    lock_and_call_power_command("suspend")
end

function power.reboot()
    shutdown.clean_shutdown('Reboot', 30,
        function() call_power_command("reboot") end)
end

function power.hibernate()
    lock_and_call_power_command("hibernate")
end

function power.poweroff()
    shutdown.clean_shutdown('Power off', 30,
        function() call_power_command("poweroff") end)
end

function power.quit()
    shutdown.clean_shutdown('Quit awesome', 30, awesome.quit)
end

function power.power_menu()
    local notification = nil
    local function call(f)
        return function()
            naughty.destroy(notification,
                    naughty.notificationClosedReason.dismissedByUser)
            f()
        end
    end

    notification = naughty.notify({
        title='Power',
        text='Choose action to take.',
        timeout=30,
        actions={
            ['power off']=call(power.poweroff),
            suspend=call(power.suspend),
            hibernate=call(power.hibernate),
            reboot=call(power.reboot),
            ['quit awesome']=call(power.quit),
            cancel=call(function() end),
        }
    })
end

awesome.connect_signal("startup",
    function()
        local systemctl_command = command.get_available_command({
            {command="systemctl"}})
        if systemctl_command then
            commands = {
                suspend=systemctl_command .. " suspend",
                reboot=systemctl_command .. " reboot",
                hibernate=systemctl_command .. " hibernate",
                poweroff=systemctl_command .. " poweroff",
            }
            local power_key_inhibitor = dbus_.inhibit(
                "handle-suspend-key:handle-lid-switch:handle-power-key",
                "Handle power keys by awesome", "block")

        else
            commands = {
                suspend="sudo pm-suspend",
                poweroff="sudo poweroff",
                reboot="sudo reboot",
            }
        end
    end)

return power
