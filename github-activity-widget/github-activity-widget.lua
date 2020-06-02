-------------------------------------------------
-- GitHub Widget for Awesome Window Manager
-- Shows the number of currently assigned issues
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/github-activity-widget

-- @author Pavel Makhov
-- @copyright 2020 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local json = require("json")
local spawn = require("awful.spawn")
local naughty = require("naughty")
local gears = require("gears")
local beautiful = require("beautiful")
local gfs = require("gears.filesystem")


local HOME_DIR = os.getenv("HOME")
local WIDGET_DIR = HOME_DIR .. '/.config/awesome/awesome-wm-widgets/github-activity-widget/'
local ICONS_DIR = WIDGET_DIR .. 'icons/'
local CACHE_DIR = HOME_DIR .. '/.cache/awmw/github-activity-widget/'

local GET_ISSUES_CMD = [[bash -c "cat /home/pmakhov/.cache/awmw/github-activity-widget/activity.json | jq '.[:%d] | [.[] | {type: .type, actor: .actor, repo: .repo, action: .payload.action, issue_url: .payload.issue.html_url, pr_url: .payload.pull_request.html_url, created_at: .created_at}]'"]]
local DOWNLOAD_AVATAR_CMD = [[bash -c "curl -n --create-dirs -o  %s/avatars/%s %s"]]
local UPDATE_EVENTS_CMD = [[bash -c "curl -s --show-error https://api.github.com/users/%s/received_events > ~/.cache/awmw/github-activity-widget/activity.json"]]

--- Utility function to show warning messages
local function show_warning(message)
    naughty.notify{
        preset = naughty.config.presets.critical,
        title = 'GitHub Activity Widget',
        text = message}
end

--- Converts string representation of date to date
local function parse_date(date_str)
    local pattern = "(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)%Z"
    local y, m, d, h, min, sec, mil = date_str:match(pattern)

    return os.time{year = y, month = m, day = d, hour = h, min = min, sec = sec}
end

--- Converts seconds to "time ago" represenation, like '1 hour ago'
local function to_time_ago(seconds)
    local days = seconds / 86400
    if days > 1 then
        days = math.floor(days + 0.5)
        return days .. (days == 1 and ' day' or ' days') .. ' ago'
    end

    local hours = (seconds % 86400) / 3600
    if hours > 1 then
        hours = math.floor(hours + 0.5) 
        return hours .. (hours == 1 and ' hour' or ' hours') .. ' ago'
    end

    local minutes = ((seconds % 86400) % 3600) / 60
    if minutes > 1 then
        minutes = math.floor(minutes + 0.5)
        return minutes .. (minutes == 1 and ' minute' or ' minutes') .. ' ago'
    end
end


local popup = awful.popup{
    ontop = true,
    visible = false,
    shape = gears.shape.rounded_rect,
    border_width = 1,
    border_color = beautiful.bg_focus,
    maximum_width = 350,
    offset = { y = 5 },
    widget = {}
}

local type_to_text_mapping = {
    WatchEvent = 'starred',
    CommitCommentEvent = '',
    CreateEvent = 'created',
    DeleteEvent = '',
    ForkEvent = 'forked',
    GollumEvent = '',
    IssueCommentEvent = '',
    IssuesEvent = '',
    MemberEvent = '',
    PublicEvent = '',
    PullRequestEvent = '',
    PullRequestReviewCommentEvent = '',
    PushEvent = 'pushed',
    ReleaseEvent = '',
    SponsorshipEvent = ''
}

local function generate_action_string(event)
    local action_string = type_to_text_mapping[event.type]
    local icon = 'repo.svg'
    local link = 'http://github.com/' .. event.repo.name

    if (event.type == "PullRequestEvent") then
        action_string = event.action .. ' a pull request in'
        link = event.pr_url
        icon = 'pr.svg'
    elseif (event.type == "IssuesEvent") then
        action_string = event.action .. ' an issue in'
        link = event.issue_url
        icon = 'issue.svg'
    elseif (event.type == "IssueCommentEvent") then
        action_string = event.action == 'created' and 'commented in issue' or event.action .. ' a comment in'
        link = event.issue_url
        icon = 'comment.svg'
    elseif (event.type == "WatchEvent") then
        action_string = 'starred'
        link = 'http://github.com/' .. event.repo.name
        icon = 'star.svg'
    elseif (event.type == "ForkEvent") then
        action_string = 'forked'
        link = 'http://github.com/' .. event.repo.name
        icon = 'fork.svg'
    end

    return { action_string = action_string, link = link, icon = icon }
end

local github_widget = wibox.widget {
    {
        {
            id = 'icon',
            widget = wibox.widget.imagebox
        },
        id = "m",
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
    set_icon = function(self, new_icon)
        self.m.icon.image = new_icon
    end,
    set_text = function(self, new_value)
        self.txt.text = new_value
    end,
    set_unseen_review = function(self, is_new_review)
        self.new_rev.text = is_new_review and '*' or ''
    end
}


local function worker(args)

    local args = args or {}

    local icon = args.icon or ICONS_DIR .. 'github.png'
    local username = args.username or show_warning('No username provided')
    local number_of_events = args.number_of_events or 10

    github_widget:set_icon(icon)

    local current_number_of_reviews
    local previous_number_of_reviews = 0

    local rows = {
        { widget = wibox.widget.textbox },
        layout = wibox.layout.fixed.vertical,
    }

    local update_widget = function(widget, stdout, stderr, _, _)
        if stderr ~= '' then
            show_warning(stderr)
            return
        end

        local current_time = os.time(os.date("!*t"))

        local result = json.decode(stdout)

        current_number_of_reviews = rawlen(result)

        if current_number_of_reviews == 0 then
            widget:set_visible(false)
            return
        end

        widget:set_visible(true)
        -- widget:set_text(current_number_of_reviews)

        for i = 0, #rows do rows[i]=nil end
        for _, issue in ipairs(result) do
            local path_to_avatar = CACHE_DIR .. '/avatars/' .. issue.actor.id

            if not gfs.file_readable(path_to_avatar) then
                spawn.easy_async(string.format(
                        DOWNLOAD_AVATAR_CMD,
                        CACHE_DIR,
                        issue.actor.id,
                        issue.actor.avatar_url))
            end

            local action_and_link = generate_action_string(issue)

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
                                markup = '<b> ' .. issue.actor.display_login .. '</b> ' .. action_and_link.action_string .. ' <b>' .. issue.repo.name .. '</b>',
                                wrap = 'word',
                                widget = wibox.widget.textbox
                            },
                            {
                                {
                                    {
                                        image = ICONS_DIR .. action_and_link.icon,
                                        resize = true,
                                        forced_height = 16,
                                        forced_width = 16,
                                        widget = wibox.widget.imagebox
                                    },
                                    valign = 'center',
                                    layout = wibox.container.place
                                },
                                {
                                    markup = to_time_ago(os.difftime(current_time, parse_date(issue.created_at))),
                                    widget = wibox.widget.textbox
                                },
                                spacing = 4,
                                layout = wibox.layout.fixed.horizontal,
                            },
                            layout = wibox.layout.align.vertical
                        },
                        spacing = 4,
                        layout = wibox.layout.fixed.horizontal
                    },
                    margins = 4,
                    layout = wibox.container.margin
                },
                bg = beautiful.bg_normal,
                widget = wibox.container.background
            }

            row:connect_signal("mouse::enter", function(c) c:set_bg(beautiful.bg_focus) end)
            row:connect_signal("mouse::leave", function(c) c:set_bg(beautiful.bg_normal) end)

            row:buttons(
                    awful.util.table.join(
                            awful.button({}, 1, function()
                                spawn.with_shell("xdg-open " .. action_and_link.link)
                                popup.visible = false
                            end)
                    )
            )

            table.insert(rows, row)
        end

        popup:setup(rows)
    end

    github_widget:buttons(
            awful.util.table.join(
                    awful.button({}, 1, function()
                        if popup.visible then
                            popup.visible = not popup.visible
                        else
                            spawn.easy_async(string.format(GET_ISSUES_CMD, number_of_events), function (stdout, stderr)
                                update_widget(github_widget, stdout, stderr)
                                popup:move_next_to(mouse.current_widget_geometry)
                            end)
                        end
                    end)
            )
    )

    gears.timer {
        timeout   = 600,
        call_now  = true,
        autostart = true,
        callback  = function()
            spawn.easy_async(string.format(UPDATE_EVENTS_CMD, username), function(stdout, stderr)
                if stderr ~= '' then
                    show_warning(stderr)
                    return
                end
            end)
        end
    }
    return github_widget
end

return setmetatable(github_widget, { __call = function(_, ...) return worker(...) end })
