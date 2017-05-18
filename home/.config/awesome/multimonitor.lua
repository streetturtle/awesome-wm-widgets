local gears = require("gears")
local awful = require("awful")
local async = require("async")
require("awful.autofocus")
local naughty = require("naughty")
local wibox = require("wibox")

local xrandr = require("xrandr")
local debug_util = require("debug_util")
local json = require("json/json")
local variables = require("variables")

local function show_screens()
    for s in screen do
        local title = "Screen " .. s.index
        local text = ""
        for k, _ in pairs(s.outputs) do
            text = text .. k .. " "
        end
        text = text .. " " .. s.geometry.width .. "x" .. s.geometry.height
                .. "+" .. s.geometry.x .. "+" .. s.geometry.y
        naughty.notify({text=text, title=title, screen=s})
    end
end

local configured_outputs = {}
local current_screen_layout = ""
local configured_outputs_file = variables.config_dir .. "/outputs.json"

-- This function modifies its argument!!
local function get_layout_key(screens)
    table.sort(screens)
    local result = ""
    for _, s in ipairs(screens) do
        result = result .. s .. " "
    end
    return result
end

local function get_current_configuration(key)
    local current_configuration = configured_outputs[
            get_layout_key(xrandr.outputs().connected)]
    if key == nil then
        return current_configuration
    end
    if current_configuration then
        if not current_configuration then
            current_configuration[key] = {}
        end
        return current_configuration[key]
    end
    return nil
end

local function save_configured_outputs()
    local content = json.encode(configured_outputs)
    debug_util.log("Saving screen configuration")
    local f = io.open(configured_outputs_file, "w")
    f:write(content)
    f:close()
end

local function load_configured_outputs()
    local f = io.open(configured_outputs_file, "r")
    local content = f:read("*a")
    debug_util.log("Loaded screen configuration")
    configured_outputs = json.decode(content)
    f:close()
end

local function get_screen_name(s)
    return gears.table.keys(s.outputs)[1]
end

local function find_clients(s)
    local result = {}
    for _, c in ipairs(s.all_clients) do
        table.insert(result, tostring(c.window))
    end
    return result
end

local function initialize_client_configuration()
    local client_configuration = get_current_configuration("clients")
    if not client_configuration then
        return
    end
    for k, _ in pairs(client_configuration) do
        client_configuration[k] = nil
    end
    for _, c in pairs(client.get()) do
        client_configuration[tostring(c.window)] =
                {screen=get_screen_name(c.screen)}
    end
end

local function get_active_screen_layout()
    local screen_names = {}
    local offsets = {}
    for s in screen do
        local name = get_screen_name(s)
        screen_names[s.geometry.x] = name
        table.insert(offsets, s.geometry.x)
    end
    table.sort(offsets)

    local layout = {}
    local layout_names = ""
    for _, offset in ipairs(offsets) do
        local name = screen_names[offset]
        layout_names = layout_names .. name .. "-"
        table.insert(layout, name)
    end
    return {layout=layout, layout_names=layout_names}
end

local function save_screen_layout()
    local active_layout = get_active_screen_layout()
    local key = get_layout_key(xrandr.outputs().connected)
    local configuration = configured_outputs[key]

    debug_util.log("Saving screen layout for configuration " .. key
            .. ": " .. active_layout.layout_names)

    if active_layout.layout_names ~= current_screen_layout then
        debug_util.log("Screen layout is not up to date. Not saving.")
        return
    end

    if not configuration then
        configuration = {}
        configured_outputs[key] = configuration
    end

    configuration.layout = active_layout.layout
    if not configuration.clients then
        configuration.clients = {}
    end
    initialize_client_configuration()
    save_configured_outputs()
end

local function get_screens_by_name()
    local screens = {}
    for s in screen do
        screens[get_screen_name(s)] = s
    end
    return screens
end

local function restore_clients(clients)
    debug_util.log("Restoring client positions")
    local screens = get_screens_by_name()
    local to_move = {}
    for _, c in ipairs(client.get()) do
        local client_info = clients[tostring(c.window)]
        local screen_name = nil
        if client_info then
            screen_name = client_info.screen
        end
        if screen_name and screen_name ~= get_screen_name(c.screen) then
            debug_util.log("Moving client "
                    .. debug_util.get_client_debug_info(c)
                    .. " to screen " .. screen_name)
            to_move[c] = screens[screen_name]
        end
    end
    for c, s in pairs(to_move) do
        c:move_to_screen(s)
    end
end

local function handle_xrandr_finished(_, configuration)
    if configuration.clients then
        restore_clients(configuration.clients)
    end
    if configuration.system_tray_screen then
        local screens = get_screens_by_name()
        local system_tray_screen = configuration.system_tray_screen
        wibox.widget.systray().set_screen(screens[system_tray_screen])
    else
        wibox.widget.systray().set_screen("primary")
    end
    save_screen_layout()
end

local function detect_screens()
    local out = xrandr.outputs()
    local key = get_layout_key(out.connected)
    debug_util.log("Detected screen configuration: " .. key)
    naughty.notify({title="Detected configuration", text=key})
    local configuration = configured_outputs[key]
    if configuration then
        local layout_string = ""
        for _, name in ipairs(configuration.layout) do
            layout_string = layout_string .. name .. "-"
        end
        debug_util.log("Setting new screen layout: " .. layout_string)
        current_screen_layout = layout_string
        async.spawn_and_get_output(
                xrandr.command(out.all, configuration.layout, true),
                function(_)
                    handle_xrandr_finished(key, configuration)
                end)
    else
        debug_util.log("No previously saved layout found.")
        save_screen_layout()
    end
end

local function clear_layout(_)
    local out = xrandr.outputs()
    local key = get_layout_key(out.connected)
    debug_util.log("Clearing screen layout for " .. key)
    configured_outputs[key] = nil
end

local function print_debug_info()
    naughty.notify({text=debug_util.to_string_recursive(configured_outputs),
            timeout=20})
end

local function manage_client(c)
    -- local active_screens = ""
    -- for s in screen do
    --     active_screens = active_screens .. get_screen_name(s) .. "-"
    -- end
    -- debug_util.log("Active screens: " .. active_screens)

    local client_configuration = get_current_configuration("clients")
    local active_layout = get_active_screen_layout()
    if client_configuration and
            active_layout.layout_names == current_screen_layout then
        client_configuration[tostring(c.window)] = {
                screen=get_screen_name(c.screen)}
        save_configured_outputs()
    end
end

local function unmanage_client(c)
    local client_configuration = get_current_configuration("clients")
    if client_configuration then
        client_configuration[tostring(c.window)] = nil
    end
end

local function set_system_tray_position()
    local target_screen = mouse.screen
    wibox.widget.systray().set_screen(target_screen)
    local configuration = get_current_configuration(nil)
    if configuration then
        naughty.notify({text="Found configuration"})
        configuration.system_tray_screen = get_screen_name(target_screen)
    else
        naughty.notify({text="Found no configuration"})
    end
    save_screen_layout()
end

local function cleanup_clients()
    local active_clients = {}
    for _, c in pairs(client.get()) do
        active_clients[tostring(c.window)] = true
    end
    local to_remove = {}
    for _, configuration in pairs(configured_outputs) do
        if configuration.clients then
            for window, _ in pairs(configuration.clients) do
                if not active_clients[window] then
                    table.insert(to_remove, window)
                end
            end
            for _, window in pairs(to_remove) do
                configuration.clients[window] = nil
            end
        end
    end
end

if gears.filesystem.file_readable(configured_outputs_file) then
    load_configured_outputs()
    cleanup_clients()
end

return {
    show_screens=show_screens,
    detect_screens=detect_screens,
    clear_layout=clear_layout,
    print_debug_info=print_debug_info,
    manage_client=manage_client,
    unmanage_client=unmanage_client,
    set_system_tray_position=set_system_tray_position
}
