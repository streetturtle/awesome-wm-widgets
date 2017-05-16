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
local client_configuration = nil
local system_tray_screen = nil
local configured_outputs_file = variables.config_dir .. "/outputs.json"

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

-- This function modifies its argument!!
local function get_layout_key(screens)
    table.sort(screens)
    local result = ""
    for _, s in ipairs(screens) do
        result = result .. s .. " "
    end
    return result
end

local function get_active_screens()
    local screens = {}
    for s in screen do
        table.insert(screens, get_screen_name(s))
    end
    return screens
end

local function find_clients(s)
    local result = {}
    for _, c in ipairs(s.all_clients) do
        table.insert(result, tostring(c.window))
    end
    return result
end

local function initialize_client_configuration()
    for k, _ in pairs(client_configuration) do
        client_configuration[k] = nil
    end
    for _, c in pairs(client.get()) do
        client_configuration[tostring(c.window)] =
                {screen=get_screen_name(c.screen)}
    end
end

local function save_screen_layout()
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

    local key = get_layout_key(get_active_screens())
    local configuration = configured_outputs[key]

    debug_util.log("Saving screen layout for configuration " .. key
            .. ": " .. layout_names)

    if not configuration then
        configuration = {}
        configured_outputs[key] = configuration
    end

    configuration.layout = layout
    if not configuration.clients then
        configuration.clients = {}
    end
    client_configuration = configuration.clients
    initialize_client_configuration()
    configuration.system_tray_screen = system_tray_screen
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
    local screens = get_screens_by_name()
    local to_move = {}
    for _, c in ipairs(client.get()) do
        local screen_name = clients[tostring(c.window)]
        if screen_name ~= get_screen_name(c.screen) then
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
        system_tray_screen = configuration.system_tray_screen
        wibox.widget.systray().set_screen(screens[system_tray_screen])
    else
        system_tray_screen = nil
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
    if client_configuration then
        client_configuration[tostring(c.window)] = {screen=get_screen_name(c.screen)}
        save_configured_outputs()
    end
end

local function unmanage_client(c)
    if client_configuration then
        client_configuration[tostring(c.window)] = nil
    end
end

local function set_system_tray_position()
    local target_screen = mouse.screen
    wibox.widget.systray().set_screen(target_screen)
    system_tray_screen = get_screen_name(target_screen)
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
    switch_off_unknown_outputs=switch_off_unknown_outputs,
    manage_client=manage_client,
    unmanage_client=unmanage_client,
    set_system_tray_position=set_system_tray_position
}
