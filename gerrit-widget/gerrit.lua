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

local GET_CHANGES_CMD = [[bash -c "curl -s -X GET -n https://%s/a/changes/\\?q\\=%s | tail -n +2"]]
local GET_USERNAME_CMD = [[bash -c "curl -s -X GET -n https://%s/accounts/%s/name | tail -n +2 | sed 's/\"//g'"]]

local gerrit_widget = {}
local name_dict = {}

local function worker(args)

    local args = args or {}

    local host = args.host or naughty.notify{preset = naughty.config.presets.critical, text = 'Gerrit host is unknown'}
    local query = args.query or 'is:reviewer AND status:open AND NOT is:wip'

    local reviews
    local notification_text

    gerrit_widget = wibox.widget{
        widget = wibox.widget.textbox
    }

    local function get_name_by_id(id)
        res = name_dict[id]
        if res == nil then
            res = ''
            spawn.easy_async(string.format(GET_USERNAME_CMD, host, id), function(stdout, stderr, reason, exit_code)
                name_dict[tonumber(id)] = stdout
            end)
        end
        return res
    end

    local update_graphic = function(widget, stdout, _, _, _)
        reviews = json.decode(stdout)
        widget.text = rawlen(reviews)

        notification_text = ''
        for _, review in ipairs(reviews) do
            notification_text = notification_text .. "<b>" .. review.project ..'</b> / ' .. get_name_by_id(review.owner._account_id) .. review.subject ..'\n'
        end
    end

    local notification
    gerrit_widget:connect_signal("mouse::enter", function()
        notification = naughty.notify{
            text = notification_text,
            timeout = 20,
            position = position,
            width = (500)
        }
    end)

    gerrit_widget:connect_signal("mouse::leave", function()
        naughty.destroy(notification)
    end)

    watch(string.format(GET_CHANGES_CMD, host, query:gsub(" ", "+")), 1, update_graphic, gerrit_widget)
    return gerrit_widget
end

return setmetatable(gerrit_widget, { __call = function(_, ...) return worker(...) end })
