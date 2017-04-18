--- Separating Multiple Monitor functions as a separeted module (taken from awesome wiki)

local awful      = require("awful")
local gears      = require("gears")
local naughty    = require("naughty")

-- A path to a fancy icon
local icon_path = ""

local function parse_outputs(pattern)
    local outputs = {}
    local xrandr = io.popen("xrandr -q --current")

    if xrandr then
        for line in xrandr:lines() do
            local output = line:match(pattern)
            if output then
                outputs[#outputs + 1] = output
            end
        end
        xrandr:close()
    end

    return outputs
end

-- Get active outputs
local function outputs()
    return parse_outputs("^([%w-]+) connected ")
end

-- Get all outputs
local function all_outputs()
    return gears.table.join(outputs(), parse_outputs("^([%w-]+) disconnected "))
end

local function arrange(out)
    -- We need to enumerate all permutations of horizontal outputs.

    local choices  = {}
    local previous = { {} }
    for i = 1, #out do
        -- Find all permutation of length `i`: we take the permutation
        -- of length `i-1` and for each of them, we create new
        -- permutations by adding each output at the end of it if it is
        -- not already present.
        local new = {}
        for _, p in pairs(previous) do
            for _, o in pairs(out) do
                if not awful.util.table.hasitem(p, o) then
                    new[#new + 1] = awful.util.table.join(p, {o})
                end
            end
        end
        choices = awful.util.table.join(choices, new)
        previous = new
    end

    return choices
end

local function command(out, choice, rearrange)
     local cmd = "xrandr"
     -- Enabled outputs
     if rearrange then
         for i, o in pairs(choice) do
             cmd = cmd .. " --output " .. o .. " --auto"
             if i > 1 then
                 cmd = cmd .. " --right-of " .. choice[i-1]
             end
         end
     end
     -- Disabled outputs
     for _, o in pairs(out) do
         if not awful.util.table.hasitem(choice, o) then
             cmd = cmd .. " --output " .. o .. " --off"
         end
     end
     return cmd
end

-- Build available choices
local function menu()
    local menu = {}
    local all = all_outputs()
    local out = outputs()
    local choices = arrange(out)

    for _, choice in pairs(choices) do
        local cmd = command(all, choice, true)

        local label = ""
        if #choice == 1 then
            label = 'Only <span weight="bold">' .. choice[1] .. '</span>'
        else
            for i, o in pairs(choice) do
                if i > 1 then label = label .. " + " end
                label = label .. '<span weight="bold">' .. o .. '</span>'
            end
        end

        menu[#menu + 1] = { label, cmd, choice }
    end

    return menu
end

-- Display xrandr notifications from choices
local state = { cid = nil }

local function naughty_destroy_callback(reason, callback_before, callback_after)
    if reason == naughty.notificationClosedReason.expired or
        reason == naughty.notificationClosedReason.dismissedByUser then
        local action = state.index and state.menu[state.index - 1][2]
        if action then
            local layout = state.menu[state.index - 1][3]
            callback_before(layout)
            awful.spawn.easy_async(action,
                    function(_, _, _, _)
                        callback_after(layout)
                    end)
            state.index = nil
        end
    end
end

local function xrandr(callback_before, callback_after)
    -- Build the list of choices
    if not state.index then
        state.menu = menu()
        state.index = 1
    end

    -- Select one and display the appropriate notification
    local label, _
    local next  = state.menu[state.index]
    state.index = state.index + 1

    if not next then
        label = "Keep the current configuration"
        state.index = nil
    else
        label, _ = unpack(next)
    end
    state.cid = naughty.notify({
            text = label,
            icon = icon_path,
            timeout = 4,
            screen = mouse.screen,
            replaces_id = state.cid,
            destroy = function(reason)
                naughty_destroy_callback(reason, callback_before,
                        callback_after)
            end}).id
end

return {
    outputs = outputs,
    all_outputs = all_outputs,
    arrange = arrange,
    menu = menu,
    command = command,
    xrandr = xrandr
}
