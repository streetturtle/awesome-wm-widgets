local spawn = require("awful.spawn")

local wpctl = {}

wpctl.LIST_DEVICES_CMD = [[wpctl status]]
wpctl.LIST_SINK_INPUTS_CMD = [[pactl list sink-inputs]]

function wpctl:get_volume_cmd()
    return "wpctl get-volume @DEFAULT_AUDIO_SINK@"
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

function wpctl:inc_volume_cmd(s)
    return string.format("wpctl set-volume @DEFAULT_AUDIO_SINK@ %d%%+", s or self.step)
end

function wpctl:inc_volume()
    spawn.easy_async(self:inc_volume_cmd(), notify_default_changed(self))
end

function wpctl:dec_volume_cmd(s)
    return string.format("wpctl set-volume @DEFAULT_AUDIO_SINK@ %d%%-", s or self.step)
end

function wpctl:dec_volume()
    spawn.easy_async(self:dec_volume_cmd(), notify_default_changed(self))
end

function wpctl:tog_volume_cmd()
    return "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
end

function wpctl:tog_volume()
    spawn.easy_async(self:tog_volume_cmd(), notify_default_changed(self))
end

function wpctl:set_default_cmd(device_type, device_name)
    return string.format('wpctl set-default %s', device_name)
end

function wpctl:set_default(device_type, device_name)
    spawn.easy_async(self:set_default_cmd(device_type, device_name), function()
        notify_default_changed(self)()
        if self.adapter and self.adapter.notify_popup_rebuild_required then
            self.adapter.notify_popup_rebuild_required()
        end
    end)
end

function wpctl:move_sink_inputs_cmd(sink_input_id, device_name)
    return string.format([[pactl move-sink-input %s "%s"]], sink_input_id, device_name)
end

function wpctl:row_volume_up_cmd(device_type, device_name)
    return string.format('wpctl set-volume %s %d%%+', device_name, self.step)
end

function wpctl:row_volume_up(device_type, device_name, is_default)
    spawn.easy_async(self:row_volume_up_cmd(device_type, device_name), notify_device_changed(self, device_type, device_name, is_default))
end

function wpctl:row_volume_down_cmd(device_type, device_name)
    return string.format('wpctl set-volume %s %d%%-', device_name, self.step)
end

function wpctl:row_volume_down(device_type, device_name, is_default)
    spawn.easy_async(self:row_volume_down_cmd(device_type, device_name), notify_device_changed(self, device_type, device_name, is_default))
end

function wpctl:row_mute_toggle_cmd(device_type, device_name)
    return string.format('wpctl set-mute %s toggle', device_name)
end

function wpctl:row_mute_toggle(device_type, device_name, is_default)
    spawn.easy_async(self:row_mute_toggle_cmd(device_type, device_name), notify_device_changed(self, device_type, device_name, is_default))
end

function wpctl:get_row_volume_cmd(device_type, device_name)
    return string.format('wpctl get-volume %s', device_name)
end

function wpctl:parse_row_volume(stdout)
    local volume_level = stdout:match('Volume: (%d%.%d%d)')
    local is_muted = stdout:match('%[MUTED%]') ~= nil
    if volume_level then
        return math.floor(tonumber(volume_level) * 100), is_muted
    end
    return nil, is_muted
end

function wpctl:extract_sinks_and_sources(stdout)
    local sinks = {}
    local sources = {}

    local function parse_wpctl_section(section_name, target_table)
        local section_found = false
        for line in stdout:gmatch("[^\n]+") do
            if line:match(section_name) then
                section_found = true
            elseif section_found then
                if line:match("^%s*$") or (line:match(":") and not line:match("%d%.%s")) then
                    if not line:match(section_name) then break end
                end
                local is_default, id, description = line:match("([%*]?)%s*(%d+)%.%s*(.*)")
                if id then
                    local volume = 0
                    local vol_match = description:match("%[vol: (%d%.%d+)%]")
                    if vol_match then
                        volume = math.floor(tonumber(vol_match) * 100)
                    else
                        local old_vol_match = description:match("%[(%d?%d?%d)%%")
                        if old_vol_match then
                            volume = tonumber(old_vol_match)
                        end
                    end
                    local mute = description:match("%[MUTED%]") ~= nil
                    table.insert(target_table, {
                        name = id,
                        is_default = is_default == "*",
                        volume = volume,
                        mute = mute,
                        properties = { device_description = description:gsub("%s*%[.*%]", "") }
                    })
                end
            end
        end
    end

    parse_wpctl_section("Sinks:", sinks)
    parse_wpctl_section("Sources:", sources)

    return sinks, sources
end

function wpctl:parse_volume_cmd(stdout)
    return self:parse_row_volume(stdout)
end

function wpctl.new(args)
    local self = {
        adapter = args.adapter,
        step = args.step or 5
    }
    return setmetatable(self, { __index = wpctl })
end

return wpctl
