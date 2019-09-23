-------------------------------------------------
-- Gerrit Widget for Awesome Window Manager
-- Shows the number of currently assigned reviews
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/gerrit-widget

-- @author Pavel Makhov
-- @copyright 2019 Pavel Makhov
-------------------------------------------------

local wibox = require("wibox")
local watch = require("awful.widget.watch")
local json = require("json")
local spawn = require("awful.spawn")
local naughty = require("naughty")

local path_to_icons = "/usr/share/icons/Arc/status/symbolic/"
--local CMD = [[bash -c "curl  -s --request GET --netrc https://%s/a/changes/\\?q\\=%s | tail -n +2 | jq ' . | length'"]]
local CMD = [[bash -c "curl  -s --request GET --netrc https://%s/a/changes/\\?q\\=%s | tail -n +2"]]

local gerrit_widget = {}

local function worker(args)

    local args = args or {}

    local host = args.host or naughty.notify{preset = naughty.config.presets.critical, text = 'Gerrit host is unknown'}
    local query = args.query or 'status:open+AND+NOT+is:wip+AND+is:reviewer'

    local reviews
    local notification_text = ''

    gerrit_widget = wibox.widget{
        --font = 'Play 12',
        widget = wibox.widget.textbox
    }

    local get_size = function (T)
        local count = 0
        for _ in pairs(T) do count = count + 1 end
        return count
    end

    local update_graphic = function(widget, stdout, _, _, _)
        reviews = json.decode(stdout)
        widget.text = get_size(reviews)


        for i in pairs(reviews)do
            notification_text = notification_text .. '\n' .. reviews[i].subject
            i = i + 1
        end

    end

    local function urlencode(url)
        if url == nil then
            return
        end
        url = url:gsub(" ", "+")
        return url
    end

    query_escaped = urlencode(query)
    watch(string.format(CMD, host, query_escaped), 10, update_graphic, gerrit_widget)

    local notification
    gerrit_widget:connect_signal("mouse::enter", function()
        notification = naughty.notify{
            text = notification_text,
            timeout = 5, hover_timeout = 10,
            position = position,
            width = (500)
        }
    end)

    gerrit_widget:connect_signal("mouse::leave", function()
        naughty.destroy(notification)
    end)

    return gerrit_widget
end

return setmetatable(gerrit_widget, { __call = function(_, ...) return worker(...) end })
