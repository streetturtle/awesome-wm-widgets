local gears = require("gears")
local awful = require("awful")
local async = require("async")
require("awful.autofocus")
local naughty = require("naughty")
local wibox = require("wibox")

local D = require("debug_util")
local serialize = require("serialize")
local tables = require("tables")
local variables = require("variables")
local xrandr = require("xrandr")

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
local configured_screen_layout = nil
local saved_screen_layout = ""
local configured_outputs_file = variables.config_dir .. "/outputs.json"
local layout_changing = false

local function get_screen_name(s)
    return gears.table.keys(s.outputs)[1]
end

local function move_to_screen(c, s)
    D.log(D.debug, "Moving client " .. D.get_client_debug_info(c)
        .. " to screen " .. get_screen_name(s))
    local maximized = c.maximized
    c.maximized = false
    c:move_to_screen(s)
    c.maximized = maximized
end

local function get_configuration(key)
    return tables.get(configured_outputs, key)
end

local function get_current_configuration(field)
    if not configured_screen_layout then
        return nil
    end

    local current_configuration = get_configuration(
            configured_screen_layout.key)

    if field then
        return tables.get(current_configuration, field)
    else
        return current_configuration
    end
end

local function save_configured_outputs()
    D.log(D.debug, "Saving screen configuration to file.")
    serialize.save_to_file(configured_outputs_file, configured_outputs)
end

local function load_configured_outputs()
    configured_outputs = serialize.load_from_file(configured_outputs_file)
    D.log(D.info, "Loading screen configuration from file.")
    D.log(D.debug, D.to_string_recursive(configured_outputs))
end

local function set_client_configuration(client_configuration, c)
    client_configuration[tostring(c.window)] = {
            screen=get_screen_name(c.screen),
            x=c.x, y=c.y,
            maximized=c.maximized}
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
        set_client_configuration(client_configuration, c)
    end
end

local function get_active_screen_layout()
    local result = {}
    for s in screen do
        local name = get_screen_name(s)
        local g = s.geometry
        result[name] = {
            width=g.width,
            height=g.height,
            dx=g.x,
            dy=g.y,
            connected=true,
            active=true,
        }
    end
    return result
end

local function is_screen_equal(settings1, settings2)
    if not (settings1.width == settings2.width
            and settings1.height == settings2.height
            and settings1.dx == settings2.dx
            and settings1.dy == settings2.dy) then
        return false
    end

    if settings1.orientation and settings2.orientation then
        return settings1.orientation == settings2.orientation and
                settings1.primary == settings2.primary
    else
        return true
    end
end

local function is_layout_equal_(layout1, layout2)
    for name, settings1 in pairs(layout1) do
        if not settings1.active then
            goto continue
        end
        local settings2 = layout2[name]
        if not settings2 or not settings2.active
                or not is_screen_equal(settings1, settings2) then
            return false
        end
        ::continue::
    end

    return true
end

local function is_layout_equal(layout1, layout2)
    return is_layout_equal_(layout1, layout2)
            and is_layout_equal_(layout2, layout1)
end

local function is_layout_up_to_date()
    if not configured_screen_layout then
        return false
    end

    local active_layout = get_active_screen_layout()

    return is_layout_equal(configured_screen_layout.outputs, active_layout)
end

local function save_screen_layout()
    local layout = configured_screen_layout

    if not layout then
        D.log(D.debug, "No configuration yet. Not saving.")
        return
    end

    D.log(D.debug, "Saving screen layout for configuration: "
            .. D.to_string_recursive(layout))

    if not is_layout_up_to_date() then
        D.log(D.debug, "Screen layout is not up to date. Not saving.")
        return
    end

    get_current_configuration().layout = layout

    initialize_client_configuration()
    saved_screen_layout = configured_screen_layout
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
    D.log(D.info, "Restoring client positions.")
    if not is_layout_up_to_date() then
        D.log(D.debug, "Screen layout is not up to date. Not restoring clients.")
        return
    end

    local screens = get_screens_by_name()
    local to_move = {}
    D.log(D.debug, D.to_string_recursive(clients))
    for _, c in ipairs(client.get()) do
        local client_info = clients[tostring(c.window)]
        D.log(D.debug, "Client " .. D.get_client_debug_info(c)
                .. ": " .. D.to_string_recursive(client_info))
        if client_info then
            local screen_name = client_info.screen
            local target = {
                x=client_info.x,
                y=client_info.y,
                maximized=client_info.maximized,
                screen_name=screen_name}

            if screen_name then
                target.screen = screens[screen_name]
            else
                target.screen = c.screen
                target.screen_name = get_screen_name(c.screen)
            end
            to_move[c] = target
        end
    end
    for c, target in pairs(to_move) do
        D.log(D.debug, "Moving: " .. D.get_client_debug_info(c)
                .. " x=" .. c.x .. "->" .. tostring(target.x)
                .. " y=" .. c.y .. "->" .. tostring(target.y)
                .. " screen=" .. get_screen_name(target.screen))
        move_to_screen(c, target.screen)
        if target.x then
            c.x = target.x
        end
        if target.y then
            c.y = target.y
        end
        if target.maximized ~= nil then
            c.maximized = target.maximized
        end
    end
end

local function finalize_configuration(configuration, preferred_positions)
    if not is_layout_up_to_date() then
        D.log(D.info, "Screen layout is not up to date.")
        return false
    end

    if configuration.clients then
        restore_clients(configuration.clients)
    end

    for _, preferred in pairs(preferred_positions) do
        local c = preferred.client
        D.log(D.debug, "Preferred position of client "
                .. D.get_client_debug_info(c) .. ": "
                .. D.print_property(preferred, "x") .. " "
                .. D.print_property(preferred, "y") .. " "
                .. D.print_property(preferred, "maximized"))
        local s = c.screen
        c.maximized = false
        c.x = preferred.x + s.geometry.x
        c.y = preferred.y + s.geometry.y
        c.maximized = preferred.maximized
    end

    if configuration.system_tray_screen then
        local screens = get_screens_by_name()
        local system_tray_screen = configuration.system_tray_screen
        D.log(D.info, "Moving system tray to " .. system_tray_screen)
        wibox.widget.systray().set_screen(screens[system_tray_screen])
    else
        wibox.widget.systray().set_screen("primary")
        D.log(D.info, "Moving system tray to primary screen")
    end
    save_screen_layout()
    layout_changing = false
    return true
end

local function handle_xrandr_finished(configuration, preferred_positions)
    if not finalize_configuration(configuration, preferred_positions) then
        gears.timer.start_new(0.5,
                function()
                    return not finalize_configuration(configuration,
                            preferred_positions)
                end)
    end
end

local function move_windows_to_screens(layout)
    local screens = get_screens_by_name()
    local to_move = {}

    local outputs = layout.outputs
    local target_screen = nil

    for name, output in pairs(outputs) do
        if output.active then
            target_screen = name
            break
        end
    end

    D.log(D.debug, "Move windows to screens, target=" .. target_screen)

    if not target_screen then
        return
    end

    for _, c in ipairs(client.get()) do
        local screen_name = get_screen_name(c.screen)
        D.log(D.debug, D.get_client_debug_info(c)
                .. ": x=" .. c.x .. " y=" .. c.y .. " screen=" .. screen_name)
        local current_screen = outputs[screen_name]
        if not current_screen or not current_screen.active then
            D.log(D.debug, "Need to move")
            to_move[c] = screens[target_screen]
        end
    end

    local preferred_positions = {}
    for c, s in pairs(to_move) do
        D.log(D.debug, D.get_client_debug_info(c))
        move_to_screen(c, s)
        awful.placement.no_offscreen(c)
        preferred_positions[tostring(c.window)] = {client=c,
                x=c.x - s.geometry.x, y=c.y - s.geometry.y,
                maximized=c.maximized}
    end
    return preferred_positions
end

local function set_screen_layout(configuration)
    layout_changing = true
    D.log(D.debug, "Setting new screen layout: "
            .. D.to_string_recursive(configuration.layout))
    configured_screen_layout = configuration.layout
    local preferred_positions = move_windows_to_screens(configuration.layout)

    async.spawn_and_get_output(
            "xrandr " .. configuration.layout.arguments,
            function(_)
                handle_xrandr_finished(configuration, preferred_positions)
            end)
end

local function apply_screen_layout(layout)
    local key = layout.key
    D.log(D.debug, "Reset screen layout for " .. key)
    local configuration = get_configuration(key)
    configuration.layout = layout
    configuration.clients = nil
    set_screen_layout(configuration)
end

local layout_change_notification

local function dismiss_layout_change_notification()
    naughty.destroy(layout_change_notification,
            naughty.notificationClosedReason.dismissedByCommand)
end

local function prompt_layout_change(configuration, new_layout)
    if layout_change_notification then
        dismiss_layout_change_notification()
    end
    layout_change_notification = naughty.notify({
        title="Screen layout changed",
        text="New configuration detected on " .. new_layout.key,
        timeout=30,
        actions={
            apply=function()
                D.log(D.info, "Applying new configuration")
                dismiss_layout_change_notification()
                apply_screen_layout(new_layout)
            end,
            revert=function()
                D.log(D.info, "Reverting to old configuration")
                dismiss_layout_change_notification()
                set_screen_layout(configuration)
            end,
        },
        destroy=function(reason)
            if reason == naughty.notificationClosedReason.expired then
                D.log(D.info, "Timeout - reverting to old configuration")
                set_screen_layout(configuration)
            end
        end})
end

local function on_sreen_layout_detected(layout)
    if tables.is_empty(layout.outputs) then
        return
    end
    local key = layout.key
    local configuration = configured_outputs[key]

    if configured_screen_layout and configured_screen_layout.key == key then
        if is_layout_equal(layout.outputs, configuration.layout.outputs) then
            D.log(D.debug, "Screen configuration is unchanged.")
        else
            D.log(D.info, "New screen layout detected.")
            prompt_layout_change(configuration, layout)
        end
    else
        D.log(D.info, "Detected new screen configuration: " .. key)
        if configuration then
            D.log(D.info, "Found saved configuration.")
            set_screen_layout(configuration)
        else
            D.log(D.info, "No saved configuration found.")
            apply_screen_layout(layout)
        end
    end

end

local function detect_screens()
    D.log(D.debug, "Detect screens")
    xrandr.get_outputs(on_sreen_layout_detected)
end

local function check_screens()
    if not layout_changing then
        detect_screens()
    end
end

local function print_debug_info()
    naughty.notify({text=D.to_string_recursive(configured_outputs),
            timeout=20})
end

local function save_client_position(client_configuration, c)
    D.log(D.debug, "Save client position for "
            .. D.get_client_debug_info(c))
    set_client_configuration(client_configuration, c)
    save_configured_outputs()
end

local function manage_client(c)
    local client_configuration = get_current_configuration("clients")
    if client_configuration
            and saved_screen_layout == configured_screen_layout
            and not client_configuration[tostring(c.window)] then
        D.log(D.debug, "manage " .. D.get_client_debug_info(c)
                .. " x=" .. c.x .. " y=" .. c.y)
        save_client_position(client_configuration, c)
    end
end

local function move_client(c)
    local client_configuration = get_current_configuration("clients")
    if client_configuration
            and saved_screen_layout == configured_screen_layout then
        save_client_position(client_configuration, c)
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

awesome.connect_signal("startup",
        function()
            client.connect_signal("manage", manage_client)
            client.connect_signal("property::position", move_client)
            client.connect_signal("property::size", move_client)
            client.connect_signal("unmanage", unmanage_client)
            cleanup_clients()
            detect_screens()
        end)

if gears.filesystem.file_readable(configured_outputs_file) then
    load_configured_outputs()
end

local screen_check_timer = gears.timer({
        timeout=2,
        autostart=true,
        callback=check_screens,
        single_shot=false})

return {
    detect_screens=detect_screens,
    get_screen_name=get_screen_name,
    move_to_screen=move_to_screen,
    print_debug_info=print_debug_info,
    set_system_tray_position=set_system_tray_position,
    show_screens=show_screens,
}
