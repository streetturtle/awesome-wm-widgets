local debug_util = require("debug_util")
local async = require("async")

local rex = require("rex_pcre")

local xrandr = {}

local function get_xrandr_argument(outputs)
    result = ""
    for name, setting in pairs(outputs) do
        result = result .. " --output " .. name
        if not setting.active then
            result = result .. " --off"
        else
            if setting.primary then
                result = result .. " --primary"
            end
            local resolution
            if setting.orientation == "left"
                    or setting.orientation == "right" then
                resolution = tostring(setting.height) .. "x"
                        .. tostring(setting.width)
            else
                resolution = tostring(setting.width) .. "x"
                        .. tostring(setting.height)
            end
            result = result
                    .. " --mode " .. resolution
                    .. " --pos " .. string.format("%d", setting.dx)
                    .. "x" .. string.format("%d", setting.dy)
                    .. " --rotate " .. setting.orientation
        end
    end
    return result
end

local function get_output_configuration(outputs)
    configuration = {}
    for name, setting in pairs(outputs) do
        if setting.connected then
            table.insert(configuration, name)
        end
    end
    table.sort(configuration)

    local result = ""
    for _, s in ipairs(configuration) do
        result = result .. s .. " "
    end
    return result
end

local function min_or_set(value, new_value)
    if value then
        return math.min(value, new_value)
    else
        return new_value
    end
end

function xrandr.get_outputs(callback)
    local result = {}
    local minx = nil
    local miny = nil
    async.spawn_and_get_lines(
            "xrandr -q",
            function(line)
                -- debug_util.log("-> " .. line)
                local output, primary, active, width, height, dx, dy, orientation =
                        rex.match(line,
                                "^([\\w-]+) connected (primary )?" ..
                                "((\\d+)x(\\d+)\\+(\\d+)\\+(\\d+) )?(\\w+)?")
                if output then
                    if not active then
                        result[output] = {connected=true, active=false}
                    else
                        if not orientation then
                            orientation = "normal"
                        else
                            orientation = rex.gsub(orientation, " $", "")
                        end
                        if primary then
                            primary = true
                        end
                        result[output] = {
                            active=true,
                            connected=true,
                            width=tonumber(width),
                            height=tonumber(height),
                            dx=tonumber(dx),
                            dy=tonumber(dy),
                            primary=primary,
                            orientation=orientation
                        }
                        minx = min_or_set(minx, dx)
                        miny = min_or_set(miny, dy)
                    end
                else
                    output = rex.match(line, "^([\\w-]+) disconnected")
                    if output then
                        result[output] = {connected=false, active=false}
                    end
                end
            end,
            nil,
            function()
                -- debug_util.log("xrandr finished")
                for _, layout in pairs(result) do
                    if layout.dx then
                        layout.dx = layout.dx - minx
                    end
                    if layout.dy then
                        layout.dy = layout.dy - miny
                    end
                end
                callback({
                    outputs=result,
                    arguments=get_xrandr_argument(result),
                    key=get_output_configuration(result)})
            end)
end

return xrandr
