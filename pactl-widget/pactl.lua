local spawn = require("awful.spawn")
local awful = require("awful")
local utils = require("awesome-wm-widgets.pactl-widget.utils")

local pactl = {}

-- Cached volume/mute state, updated asynchronously via update_async()
local cache = {}

-- Build a pactl argv table with the C locale forced for consistent output.
local function pactl_cmd(...)
    return {'env', 'LC_ALL=C', 'pactl', ...}
end

function pactl.volume_increase(device, step)
    spawn(pactl_cmd('set-sink-volume', device, '+' .. step .. '%'), false)
end

function pactl.volume_decrease(device, step)
    spawn(pactl_cmd('set-sink-volume', device, '-' .. step .. '%'), false)
end

function pactl.mute_toggle(device)
    spawn(pactl_cmd('set-sink-mute', device, 'toggle'), false)
end

function pactl.get_volume(device)
    return cache[device] and cache[device].volume
end

function pactl.get_mute(device)
    return cache[device] and cache[device].mute or false
end

function pactl.update_async(device, callback)
    awful.spawn.easy_async(pactl_cmd('get-sink-volume', device), function(vol_stdout, _, _, vol_exit)
        if vol_exit ~= 0 then
            cache[device] = nil
            if callback then callback(nil, false) end
            return
        end

        if not cache[device] then cache[device] = {} end

        local volsum, volcnt = 0, 0
        for vol in string.gmatch(vol_stdout, "(%d?%d?%d)%%") do
            vol = tonumber(vol)
            if vol ~= nil then
                volsum = volsum + vol
                volcnt = volcnt + 1
            end
        end

        if volcnt > 0 then
            cache[device].volume = volsum / volcnt
        end

        awful.spawn.easy_async(pactl_cmd('get-sink-mute', device), function(mute_stdout, _, _, mute_exit)
            if mute_exit ~= 0 then
                cache[device] = nil
                if callback then callback(nil, false) end
                return
            end
            cache[device].mute = string.find(mute_stdout, "yes") ~= nil
            if callback then
                callback(cache[device].volume, cache[device].mute)
            end
        end)
    end)
end

function pactl.get_sinks_and_sources()
    local default_sink = utils.trim(utils.popen_and_return(
        table.concat(pactl_cmd('get-default-sink'), ' ')))
    local default_source = utils.trim(utils.popen_and_return(
        table.concat(pactl_cmd('get-default-source'), ' ')))

    local sinks = {}
    local sources = {}

    local device
    local ports
    local key
    local value
    local in_section

    for line in utils.popen_and_return(
        table.concat(pactl_cmd('list'), ' ')):gmatch('[^\r\n]*') do

        if string.match(line, '^%a+ #') then
            in_section = nil
        end

        local is_sink_line = string.match(line, '^Sink #')
        local is_source_line = string.match(line, '^Source #')

        if is_sink_line or is_source_line then
            in_section = "main"

            device = {
                id = line:match('#(%d+)'),
                is_default = false
            }
            if is_sink_line then
                table.insert(sinks, device)
            else
                table.insert(sources, device)
            end
        end

        -- Found a new subsection
        if in_section ~= nil and string.match(line, '^\t%a+:$') then
            in_section = utils.trim(line):lower()
            in_section = string.sub(in_section, 1, #in_section-1)

            if in_section == 'ports' then
                ports = {}
                device['ports'] = ports
            end
        end

        -- Found a key-value pair
        if string.match(line, "^\t*[^\t]+: ") then
            local t = utils.split(line, ':')
            key = utils.trim(t[1]):lower():gsub(' ', '_')
            value = utils.trim(t[2])
        end

        -- Key value pair on 1st level
        if in_section ~= nil and string.match(line, "^\t[^\t]+: ") then
            device[key] = value

            if key == "name" and (value == default_sink or value == default_source) then
                device['is_default'] = true
            end
        end

        -- Key value pair in ports section
        if in_section == "ports" and string.match(line, "^\t\t[^\t]+: ") then
            ports[key] = value
        end
    end

    return sinks, sources
end

function pactl.set_default(type, name)
    spawn(pactl_cmd('set-default-' .. type, name), false)
end


return pactl
