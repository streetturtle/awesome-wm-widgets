-------------------------------------------------
-- Jira Widget for Awesome Window Manager
-- Shows the number of currently assigned issues
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/jira-widget

-- @author Pavel Makhov
-- @copyright 2019 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local watch = require("awful.widget.watch")
local json = require("json")
local spawn = require("awful.spawn")
local naughty = require("naughty")
local gears = require("gears")
local beautiful = require("beautiful")
local gfs = require("gears.filesystem")
local gs = require("gears.string")

local HOME_DIR = os.getenv("HOME")

local GET_ISSUES_CMD = [[bash -c "curl -s -X GET -n '%s/rest/api/2/search?%s&fields=id,assignee,summary,status'"]]
local DOWNLOAD_AVATAR_CMD = [[bash -c "curl -n --create-dirs -o  %s/.cache/awmw/jira-widget/avatars/%s %s"]]

local jira_widget = {}

local function worker(args)

    local args = args or {}

    local icon = args.icon or HOME_DIR .. '/.config/awesome/awesome-wm-widgets/jira-widget/jira-mark-gradient-blue.svg'
    local host = args.host or naughty.notify{
        preset = naughty.config.presets.critical, 
        title = 'Jira Widget',
        text = 'Jira host is unknown'}
    local query = args.query or 'jql=assignee=currentuser() AND resolution=Unresolved'

    local current_number_of_reviews
    local previous_number_of_reviews = 0

    local rows = {
        { widget = wibox.widget.textbox },
        layout = wibox.layout.fixed.vertical,
    }

    local popup = awful.popup{
        ontop = true,
        visible = false,
        shape = gears.shape.rounded_rect,
        border_width = 1,
        border_color = beautiful.bg_focus,
        maximum_width = 400,
        offset = { y = 5 },
        widget = {}
    }

    jira_widget = wibox.widget {
        {
            {
                image = icon,
                widget = wibox.widget.imagebox
            },
            margins = 4,
            layout = wibox.container.margin
        },
        {
            id = "txt",
            widget = wibox.widget.textbox
        },
        {
            id = "new_rev",
            widget = wibox.widget.textbox
        },
        layout = wibox.layout.fixed.horizontal,
        set_text = function(self, new_value)
            self.txt.text = new_value
        end,
        set_unseen_review = function(self, is_new_review)
            self.new_rev.text = is_new_review and '*' or ''
        end
    }

    local update_widget = function(widget, stdout, stderr, _, _)
        local result = json.decode(stdout)

        current_number_of_reviews = rawlen(result.issues)

        if current_number_of_reviews == 0 then
            widget:set_visible(false)
            return
        end

        widget:set_visible(true)
        widget:set_text(current_number_of_reviews)

        for i = 0, #rows do rows[i]=nil end
        for _, issue in ipairs(result.issues) do
            local path_to_avatar = os.getenv("HOME") ..'/.cache/awmw/jira-widget/avatars/' .. issue.fields.assignee.key

            if not gfs.file_readable(path_to_avatar) then
                spawn.easy_async(string.format(
                        DOWNLOAD_AVATAR_CMD,
                        HOME_DIR,
                        issue.fields.assignee.key,
                        issue.fields.assignee.avatarUrls['48x48']))
            end

            local row = wibox.widget {
                {
                    {
                        {
                            {
                                resize = true,
                                image = path_to_avatar,
                                forced_width = 40,
                                forced_height = 40,
                                widget = wibox.widget.imagebox
                            },
                            margins = 8,
                            layout = wibox.container.margin
                        },
                        {
                            {
                                markup = '<b>' .. issue.key .. '</b>',
                                align = 'center',
                                widget = wibox.widget.textbox
                            },
                            {
                                text = issue.fields.summary,
                                widget = wibox.widget.textbox
                            },
                            {
                                text = issue.fields.status.name,
                                widget = wibox.widget.textbox
                            },
                            layout = wibox.layout.align.vertical
                        },
                        spacing = 8,
                        layout = wibox.layout.fixed.horizontal
                    },
                    margins = 8,
                    layout = wibox.container.margin
                },
                widget = wibox.container.background
            }

            row:connect_signal("mouse::enter", function(c) c:set_bg(beautiful.bg_focus) end)
            row:connect_signal("mouse::leave", function(c) c:set_bg(beautiful.bg_normal) end)

            row:buttons(
                    awful.util.table.join(
                            awful.button({}, 1, function()
                                spawn.with_shell("xdg-open " .. host .. '/browse/' .. issue.key)
                                popup.visible = false
                            end)
                    )
            )

            table.insert(rows, row)
        end

        popup:setup(rows)
    end

    jira_widget:buttons(
            awful.util.table.join(
                    awful.button({}, 1, function()
                        if popup.visible then
                            popup.visible = not popup.visible
                        else
                            popup:move_next_to(mouse.current_widget_geometry)
                        end
                    end)
            )
    )
    --naughty.notify{
    --    text = string.format(GET_ISSUES_CMD, host, query:gsub(" ", "+")),
    --    run = function() spawn.with_shell("echo '" .. string.format(GET_ISSUES_CMD, host, query:gsub(" ", "+")) .. "' | xclip -selection clipboard") end
    --}
    watch(string.format(GET_ISSUES_CMD, host, query:gsub(' ', '+')),
            10, update_widget, jira_widget)
    return jira_widget
end

return setmetatable(jira_widget, { __call = function(_, ...) return worker(...) end })
