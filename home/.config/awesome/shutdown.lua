local naughty = require("naughty")
local gears = require("gears")

local debug_util = require("debug_util")

local function get_message(timeout)
    return 'Forcing in ' .. tostring(timeout) .. ' seconds.'
end

local function clean_shutdown(message, timeout, callback)
    debug_util.log('Stopping all clients')
    local clients_to_close = client.get()
    debug_util.log('Number of clients to stop: ' .. tostring(#clients_to_close))

    local finish = nil

    local function unmanage_client(c)
        local index = gears.table.hasitem(clients_to_close, c)
        if not index then
            return
        end

        table.remove(clients_to_close, index)
        debug_util.log('Stopped ' .. debug_util.get_client_debug_info(c)
                .. ' Number of clients remaining: '
                .. tostring(#clients_to_close))
        if #clients_to_close == 0 then
            finish(true)
        end
    end

    client.connect_signal('unmanage', unmanage_client)
    local notification = naughty.notify({
        title=message,
        text=get_message(timeout),
        timeout=0,
        actions={
            force=function()
                finish(true)
            end,
            cancel=function()
                finish(false)
            end
        },
        run=function() end
    })

    local timer = nil

    if timeout > 0 then
        local time_remaining = timeout
        timer = gears.timer.start_new(1,
            function()
                time_remaining = time_remaining - 1
                if time_remaining == 0 then
                    finish(true)
                    return false
                end
                naughty.replace_text(notification, message,
                        get_message(time_remaining))
                return true
            end)
    end

    finish = function(success)
        client.disconnect_signal('unmanage', unmanage_client)
        if timer then
            timer:stop()
        end
        naughty.destroy(notification,
                naughty.notificationClosedReason.dismissedByCommand)
        if success then
            debug_util.log('Shutdown finished. Calling callback.')
            callback()
        else
            debug_util.log('Shutdown cancelled.')
        end
    end

    for _, c in ipairs(clients_to_close) do
        c:kill()
    end
end

return {
    clean_shutdown=clean_shutdown
}
