local gears = require("gears")

local debug_util = require("debug_util")
local serialize = require("serialize")
local variables = require("variables")

local persist_data = {}
local initialized = false

local persist_file = variables.config_dir .. "/persist.json"

local function manage_client(c)
    if not initialized then
        return
    end
    debug_util.log("Saving data for client: " ..
            debug_util.get_client_debug_info(c))
    local id = tostring(c.window)
    if not persist_data.clients[id] then
        persist_data.clients[id] = {}
    end
    local client_data = persist_data.clients[id]

    if not c.maximized_horizontal and not c.maximized then
        debug_util.log("  Saving width = " .. tostring(c.width) ..
                " x = " .. tostring(c.x))
        client_data.width = c.width
        client_data.x = c.x
    end
    if not c.maximized_vertical and not c.maximized then
        debug_util.log("  Saving height = " .. tostring(c.height) ..
                " y = " .. tostring(c.y))
        client_data.height = c.height
        client_data.y = c.y
    end
    serialize.save_to_file(persist_file, persist_data)
end

local function restore_client_data(c, data)
    debug_util.log("Setting data for client: " ..
            debug_util.get_client_debug_info(c))
    local maximized = c.maximized
    local maximized_horizontal = c.maximized_horizontal
    local maximized_vertical = c.maximized_vertical
    c.maximized = false
    c.maximized_horizontal = false
    c.maximized_vertical = false

    if data.width then
        debug_util.log("  Setting width = " .. tostring(data.width))
        c.width = data.width
    end
    if data.x then
        debug_util.log("  Setting x = " .. tostring(data.x))
        c.x = data.x
    end
    if data.height then
        debug_util.log("  Setting height = " .. tostring(data.width))
        c.height = data.height
    end
    if data.y then
        debug_util.log("  Setting y = " .. tostring(data.y))
        c.y = data.y
    end

    c.maximized = maximized
    c.maximized_horizontal = maximized_horizontal
    c.maximized_vertical = maximized_vertical
end

client.connect_signal("manage", manage_client)
client.connect_signal("property::size", manage_client)
client.connect_signal("property::position", manage_client)
client.connect_signal("property::maximized", manage_client)
client.connect_signal("property::maximized_horizontal", manage_client)
client.connect_signal("property::maximized_vertical", manage_client)

client.connect_signal("unmanage",
        function(c)
            local id = tostring(c.window)
            persist_data.clients[id] = nil
        end)

awesome.connect_signal("startup",
        function()
            debug_util.log("Restoring client data")
            local to_remove = {}
            for id, data in pairs(persist_data.clients) do
                local current_client = nil
                for _, c in pairs(client.get()) do
                    if tostring(c.window) == id then
                        current_client = c
                        break
                    end
                end
                if current_client then
                    restore_client_data(current_client, data)
                else
                    debug_util.log("Client not found: " .. id)
                    table.insert(to_remove, id)
                end
            end
            initialized = true
            debug_util.log("Restoring client data done")

            for _, id in ipairs(to_remove) do
                persist_data.clients[id] = nil
            end
            serialize.save_to_file(persist_file, persist_data)
        end)

if gears.filesystem.file_readable(persist_file) then
    persist_data = serialize.load_from_file(persist_file)
end

if not persist_data.clients then
    persist_data.clients = {}
end
