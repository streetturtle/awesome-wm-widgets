local async = require("async")
-- local naughty = require("naughty")

local function xinput_action(pattern, action)
    async.spawn_and_get_lines("xinput list --short",
            function(line)
                -- naughty.notify({text=line})
                if string.match(line, pattern) then
                    local id = string.match(line, "id=(%d+)")
                    if id then
                        action(id)
                    end
                end
            end)
end

local function get_device_property(device, property, action)
    xinput_action(device,
            function(id)
                async.spawn_and_get_lines("xinput list-props " .. id,
                        function(line)
                            local value = string.match(line,
                                        property .. ".*:%s*(.*)")
                            if value then
                                action(value)
                            end
                        end)
            end)
end

local function enable_device(device, enabled)
    local value = "disable"
    if enabled then
        value = "enable"
    end
    xinput_action(device,
            function(id)
                async.spawn_and_get_output("xinput " .. value .. " " .. id,
                        function(_) end)
            end)
end

local function is_device_enabled(device, action)
    get_device_property(device, "Device Enabled",
            function(value) action(value == "1") end)
end

local function toggle_device(device)
    is_device_enabled(device,
            function(value) enable_device(device, not value) end)
end

local touchpad = "TouchPad"

return {
    enable_device=enable_device,
    is_device_enabled=is_device_enabled,
    toggle_device=toggle_device,
    touchpad=touchpad
}
