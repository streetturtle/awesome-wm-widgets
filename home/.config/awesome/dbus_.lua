local lgi = require("lgi")
local Gio = lgi.require("Gio")
local GLib = lgi.require("GLib")
local debug_util = require("debug_util")

-- Workaround for https://github.com/pavouk/lgi/issues/142
local function bus_get_async(type)
    Gio.bus_get(type, nil, coroutine.running())
    local a, b = coroutine.yield()
    return Gio.bus_get_finish(b)
end

local function inhibit_impl(bus, what, who, why, mode)
    local name = "org.freedesktop.login1"
    local object = "/org/freedesktop/login1"
    local interface = "org.freedesktop.login1.Manager"
    local message = Gio.DBusMessage.new_method_call(name, object, interface, "Inhibit")
    message:set_body(GLib.Variant("(ssss)",
        { what, who, why, mode }))

    local timeout = -1 -- Just use the default
    local result, err = bus:async_send_message_with_reply(message, Gio.DBusSendMessageFlags.NONE,
        timeout, nil)

    if err then
        debug_util.log("inhibit error: " .. tostring(err))
        return
    end

    if result:get_message_type() == "ERROR" then
        local _, err = result:to_gerror()
        debug_util.log("inhibit error: " .. tostring(err))
        return
    end

    local fd_list = result:get_unix_fd_list()
    local fd, err = fd_list:get(0)
    if err then
        debug_util.log("inhibit error: " .. tostring(err))
        return
    end

    debug_util.log("Got inhibit fd: " .. tostring(fd))

    -- Now... somehow turn this fd into something we can close
    return Gio.UnixInputStream.new(fd, false)
    -- return fd
end

local function inhibit(what, why, mode)
    local result = {}
    debug_util.log("Start inhibit")
    Gio.Async.call(function()
        debug_util.log("inhibit")
        local bus = bus_get_async(Gio.BusType.SYSTEM)
        result.stream = inhibit_impl(bus, what, "awesome", why, mode)
        debug_util.log("Got fd: " .. tostring(result.stream.fd)
                .. " closed=" .. tostring(result.stream:is_closed()))
    end)()
    return result
end

local function stop_inhibit(inhibitor)
        debug_util.log("Close fd: " .. tostring(inhibitor.stream.fd)
                .. " closed=" .. tostring(inhibitor.stream:is_closed()))
    inhibitor.stream:set_close_fd(true)
    inhibitor.stream:close()
end

return {
    inhibit=inhibit,
    stop_inhibit=stop_inhibit
}
