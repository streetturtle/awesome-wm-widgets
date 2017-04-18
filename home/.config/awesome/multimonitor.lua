local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local naughty = require("naughty")
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
local configured_outputs_file = variables.config_dir .. "/outputs.json"

local function save_configured_outputs()
    local content = json.encode(configured_outputs)
    local f = io.open(configured_outputs_file, "w")
    f:write(content)
    f:close()
end

local function load_configured_outputs()
    local f = io.open(configured_outputs_file, "r")
    local content = f:read("*a")
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
    for _, offset in ipairs(offsets) do
        table.insert(layout, screen_names[offset])
    end

    local key = get_layout_key(get_active_screens())
    local configuration = configured_outputs[key]
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
    save_configured_outputs()
end

local function switch_off_unknown_outputs()
    -- outputs = xrandr.outputs()
    -- awful.util.spawn(xrandr.command(
end

local function restore_clients(clients)
    local screens = {}
    for s in screen do
        screens[get_screen_name(s)] = s
    end
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

local function handle_xrandr_finished(key, configuration, stderr, exit_code)
    if exit_code ~= 0 then
        naughty.notify({
                preset=naughty.config.presets.critical,
                title="Error setting screen configuration",
                text=stderr})
    end
    if configuration.clients then
        restore_clients(configuration.clients)
    end
    save_screen_layout()
end

local function detect_screens()
    -- local outputs = xrandr.outputs()
    -- local text = ""
    -- for s in screen do
    --     local output = get_screen_name(s)
    --     text = text .. output .. ": "
    --     if gears.table.hasitem(outputs, output) then
    --         text = text .. " found"
    --     else
    --         text = text .. " not found"
    --     end
    --     text = text .. "\n"
    -- end
    -- naughty.notify({text=text, timeout=5, screen=1})
    local key = get_layout_key(xrandr.outputs())
    local configuration = configured_outputs[key]
    if configuration then
        naughty.notify({title="Setting new configuration",
                text=debug_util.to_string_recursive(configuration)})
        awful.spawn.easy_async(xrandr.command(xrandr.all_outputs(),
                configuration.layout, true),
                function(_, stderr, _, exit_code)
                    local result, err = xpcall(
                            function()
                                handle_xrandr_finished(key, configuration,
                                        stderr, exit_code)
                            end, debug.traceback)
                    if not result then
                        naughty.notify({
                                preset=naughty.config.presets.critical,
                                title="Error", text=err})
                    end
                end)
    else
        save_screen_layout()
    end
end

local function clear_layout(layout)
    configured_outputs[get_layout_key(layout)] = nil
end

local function print_debug_info()
    naughty.notify({text=debug_util.to_string_recursive(configured_outputs),
            timeout=10})
    -- naughty.notify({title="Current configuration",
    --         text=get_layout_key(get_active_screens()), timeout=10})
    -- naughty.notify({title="Connected outputs",
    --         text=get_layout_key(xrandr.outputs()), timeout=10})
    -- naughty.notify({title="All outputs",
    --         text=get_layout_key(xrandr.all_outputs()), timeout=10})
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
    unmanage_client=unmanage_client
}
