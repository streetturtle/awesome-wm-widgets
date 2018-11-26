local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local wibox = require("wibox")

local async = require("async")
local command = require("command")
local D = require("debug_util")
local variables = require("variables_base")

local tresorit = {}

local tresorit_command = command.get_available_command({
    {command="tresorit-cli", test="tresorit-cli status"}
})

local function on_command_finished(command, result, callback)
    local error_code = nil
    local description = nil
    local error_string = nil
    for _, line in ipairs(result.lines) do
        if line[1] == "Error code:" then
            error_code = line[2]
        elseif line[1] == "Description:" then
            description = line[2]
        end
    end
    result.has_error = false
    if error_code then
        result.has_error = true
        error_string = error_code .. ": " .. description
        D.log(D.debug, "Tresorit: error running command: " .. command)
        D.log(D.debug, error_string)
    end
    if callback then
        callback(result.lines, error_string)
    end
end

local function call_tresorit_cli(command, callback, error_handler)
    local result = {lines={}, has_error=nil}
    D.log(D.debug, "Call tresorit-cli " .. command)
    async.spawn_and_get_lines(tresorit_command .. " --porcelain " .. command, {
        line=function(line)
            table.insert(result.lines, gears.string.split(line, "\t"))
        end,
        finish=function()
            return result.has_error == nil or result.has_error
        end,
        done=function()
            local res, err = xpcall(
                function() on_command_finished(command, result, callback) end,
                debug.traceback)
            if not res then
                local handled = nil
                if error_handler then
                    handled = error_handler(err)
                end
                if not handled then
                    naughty.notify({
                        preset=naughty.config.presets.critical,
                        title="Error", text=err})
                end
            end
        end})
end

local menu_widget = awful.widget.launcher{
    image=variables.config_dir .. "/tresorit.png",
    menu=awful.menu{items={
        {"Start", function() call_tresorit_cli("start") end},
        {"Stop", function() call_tresorit_cli("stop") end},
        {"Logout", function() call_tresorit_cli("logout") end},
        {"Open GUI", function() awful.spawn("tresorit") end},
    }}
}

local stopped_widget = wibox.widget{
    image=variables.config_dir .. "/cancel.svg",
    resize=true,
    widget=wibox.widget.imagebox,
}

local logout_widget = wibox.widget{
    image=variables.config_dir .. "/question.svg",
    resize=true,
    widget=wibox.widget.imagebox,
}

local restricted_widget = wibox.widget{
    image=variables.config_dir .. "/exclamation-yellow.svg",
    resize=true,
    widget=wibox.widget.imagebox,
}

local error_widget = wibox.widget{
    image=variables.config_dir .. "/exclamation-red.svg",
    resize=true,
    widget=wibox.widget.imagebox,
}

local sync_widget = wibox.widget{
    image=variables.config_dir .. "/sync.svg",
    resize=true,
    widget=wibox.widget.imagebox,
    visible=false,
}
local sync_error_widget = wibox.widget{
    image=variables.config_dir .. "/sync-error.svg",
    resize=true,
    widget=wibox.widget.imagebox,
    visible=false,
}


tresorit.widget = wibox.widget{
    menu_widget,
    logout_widget,
    stopped_widget,
    restricted_widget,
    error_widget,
    sync_widget,
    sync_error_widget,
    layout=wibox.layout.stack,
    visible=tresorit_command ~= nil
}

local tooltip = awful.tooltip{
    objects={tresorit.widget},
    text="-"
}

local tooltip_text = "-"

local timer

local function set_tooltip_text(s)
    tooltip_text = s
end

local function append_tooltip_text(s)
    tooltip_text = tooltip_text .. s
end

local function commit()
    tooltip.text = tooltip_text
    timer:start()
end

local function on_files(result, error_string)
    if error_string then
        append_tooltip_text("\n" .. error_string)
        sync_error_widget.visible = true
        commit()
        return
    end
    status_text = ""
    for _, line in ipairs(result) do
        tresor = line[1]
        file = line[2]
        status = line[3]
        progress = line[4]
        if status then
            status_text = status_text .. "\n" .. tresor .. "/" .. file .. ": "
                .. status
        end
        if progress and progress ~= "-" then
            status_text = status_text .. " " .. progress .. "%"
        end
    end
    append_tooltip_text(status_text)
    commit()
end

local function on_transfers(result, error_string)
    if error_string then
        append_tooltip_text("\n" .. error_string)
        sync_error_widget.visible = true
        commit()
        return
    end
    local has_sync = false
    local has_error = false
    local status_text = ""
    for _, line in ipairs(result) do
        tresor = line[1]
        status = line[2]
        remaining = line[3]
        errors = tonumber(line[4])
        if status ~= "idle" then
            has_sync = true
            status_text = status_text .. "\n" .. tresor
                .. ": Files remaining: " .. remaining
        end
        if errors ~= 0 then
            has_error = true
        end
    end

    sync_widget.visible = has_sync
    sync_error_widget.visible = not has_sync and has_error
    append_tooltip_text(status_text)
    if has_sync or has_error then
        call_tresorit_cli("transfers --files", on_files, commit)
    else
        commit()
    end
end

local function on_status(result, error_string)
    -- D.log(D.debug, D.to_string_recursive(result))
    local running = false
    local logged_in = false
    local error_code = nil
    local description = nil
    local restriction_state = nil
    if error_string then
        set_tooltip_text(error_string)
    else
        set_tooltip_text("")
        for _, line in ipairs(result) do
            if line[1] == "Tresorit daemon:" then
                running = line[2] == "running"
            elseif line[1] == "Logged in as:" then
                logged_in = line[2] ~= "-"
                set_tooltip_text(line[2])
            elseif line[1] == "Restriction state:" then
                if line[2] ~= "-" then
                    restriction_state = line[2]
                end
            end
        end
    end
    D.log(D.debug, "Tresorit: running=" .. tostring(running)
        .. " logged_in=" .. tostring(logged_in)
        .. " error=" .. tostring(error_string))
    stopped_widget.visible = not error_string and not running
    logout_widget.visible = running and not logged_in
    error_widget.visible = error_string ~= nil
    restricted_widget.visible = restriction_state ~= nil

    if logged_in and not restriction_state then
        call_tresorit_cli("transfers", on_transfers, commit)
    else
        if restriction_state then
            append_tooltip_text('\n' .. restriction_state)
        end
        sync_widget.visible = false
        sync_error_widget.visible = false
        commit()
    end
end

if tresorit_command ~= nil then
    D.log(D.debug, "Has tresorit-cli")
    timer = gears.timer{
        timeout=2,
        single_shot=true,
        call_now=true,
        autostart=true,
        callback=function()
            call_tresorit_cli("status", on_status, commit)
        end}

    call_tresorit_cli("start")
else
    D.log(D.debug, "No tresorit-cli")
end

return tresorit
