local spawn = require("awful.spawn")

local pactl = {}

pactl.LIST_DEVICES_CMD = [[sh -c "pactl info && pactl list sinks && pactl list sources"]]
pactl.LIST_SINK_INPUTS_CMD = [[pactl list sink-inputs]]

function pactl:get_volume_cmd()
    return [[sh -c "pactl get-sink-volume @DEFAULT_SINK@ && pactl get-sink-mute @DEFAULT_SINK@"]]
end

local function notify_default_changed(self)
    return function()
        spawn.easy_async(self:get_volume_cmd(), function(stdout) 
            local volume, is_muted = self:parse_volume_cmd(stdout)
            if self.adapter and self.adapter.notify_default_changed then
                self.adapter.notify_default_changed(volume, is_muted)
            end
        end)
    end
end

local function notify_device_changed(self, device_type, device_name, is_default)
    return function()
        spawn.easy_async(self:get_row_volume_cmd(device_type, device_name), function(stdout)
            local volume, is_muted = self:parse_row_volume(stdout)
            if self.adapter and self.adapter.notify_device_changed then
                self.adapter.notify_device_changed(device_name, volume, is_muted, is_default)
            end
        end)
    end
end

function pactl:inc_volume_cmd()
    return string.format("pactl set-sink-volume @DEFAULT_SINK@ +%d%%", self.step)
end

function pactl:inc_volume()
    spawn.easy_async(self:inc_volume_cmd(), notify_default_changed(self))
end

function pactl:dec_volume_cmd()
    return string.format("pactl set-sink-volume @DEFAULT_SINK@ -%d%%", self.step)
end

function pactl:dec_volume()
    spawn.easy_async(self:dec_volume_cmd(), notify_default_changed(self))
end

function pactl:tog_volume_cmd()
    return "pactl set-sink-mute @DEFAULT_SINK@ toggle"
end

function pactl:tog_volume()
    spawn.easy_async(self:tog_volume_cmd(), notify_default_changed(self))
end

function pactl:set_default_cmd(device_type, device_name)
    return string.format([[pactl set-default-%s "%s"]], device_type, device_name)
end

function pactl:set_default(device_type, device_name)
    spawn.easy_async(self:set_default_cmd(device_type, device_name), function()
        notify_default_changed(self)()
        if self.adapter and self.adapter.notify_popup_rebuild_required then
            self.adapter.notify_popup_rebuild_required()
        end
    end)
end

function pactl:move_sink_inputs_cmd(sink_input_id, device_name)
    return string.format([[pactl move-sink-input %s "%s"]], sink_input_id, device_name)
end

function pactl:row_volume_up_cmd(device_type, device_name)
    return string.format([[pactl set-%s-volume "%s" +%d%%]], device_type, device_name, self.step)
end

function pactl:row_volume_up(device_type, device_name, is_default)
    spawn.easy_async(self:row_volume_up_cmd(device_type, device_name), notify_device_changed(self, device_type, device_name, is_default))
end

function pactl:row_volume_down_cmd(device_type, device_name)
    return string.format([[pactl set-%s-volume "%s" -%d%%]], device_type, device_name, self.step)
end

function pactl:row_volume_down(device_type, device_name, is_default)
    spawn.easy_async(self:row_volume_down_cmd(device_type, device_name), notify_device_changed(self, device_type, device_name, is_default))
end

function pactl:row_mute_toggle_cmd(device_type, device_name)
    return string.format([[pactl set-%s-mute "%s" toggle]], device_type, device_name)
end

function pactl:row_mute_toggle(device_type, device_name, is_default)
    spawn.easy_async(self:row_mute_toggle_cmd(device_type, device_name), notify_device_changed(self, device_type, device_name, is_default))
end

function pactl:get_row_volume_cmd(device_type, device_name)
    return string.format([[sh -c 'pactl get-%s-volume "%s" && pactl get-%s-mute "%s"']], device_type, device_name, device_type, device_name)
end

function pactl:parse_row_volume(stdout)
    local vol = stdout:match('(%d?%d?%d)%%')
    local is_muted = stdout:match('Mute: (%a+)') == 'yes'
    return tonumber(vol), is_muted
end

function pactl:parse_volume_cmd(stdout)
    return self:parse_row_volume(stdout)
end

function pactl:extract_sinks_and_sources(stdout)
    local sinks = {}
    local sources = {}
    local device_type = nil
    local current_device = nil

    local default_sink = stdout:match("Default Sink: (.-)\n")
    local default_source = stdout:match("Default Source: (.-)\n")

    for line in stdout:gmatch("[^\n]+") do
        local new_device_type = line:match("^%s*(%a+) #%d+")
        if new_device_type then
            if current_device then
                if device_type == "Sink" then table.insert(sinks, current_device) end
                if device_type == "Source" then table.insert(sources, current_device) end
            end
            device_type = new_device_type
            current_device = { properties = {} }
        end

        if current_device then
            local name = line:match("^%s+Name: (.*)")
            if name then 
                current_device.name = name 
                if name == default_sink or name == default_source then
                    current_device.is_default = true
                else
                    current_device.is_default = false
                end
            end

            local description = line:match("^%s+Description: (.*)")
            if description then current_device.properties.device_description = description end

            local volume = line:match("^%s+Volume:.-(%d+)%%")
            if volume then current_device.volume = tonumber(volume) end

            local mute = line:match("^%s+Mute: (.*)")
            if mute then current_device.mute = (mute == "yes") end
        end
    end
    if current_device then
        if device_type == "Sink" then table.insert(sinks, current_device) end
        if device_type == "Source" then table.insert(sources, current_device) end
    end

    return sinks, sources
end

function pactl.new(args)
    local self = {
        adapter = args.adapter,
        step = args.step or 5
    }
    return setmetatable(self, { __index = pactl })
end

return pactl
