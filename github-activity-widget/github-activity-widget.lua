-------------------------------------------------
-- GitHub Widget for Awesome Window Manager
-- Shows the recent activity from GitHub
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
local WIDGET_DIR = HOME_DIR .. '/.config/awesome/awesome-wm-widgets/github-activity-widget'
local ICONS_DIR = WIDGET_DIR .. '/icons/'
local CACHE_DIR = HOME_DIR .. '/.cache/awmw/github-activity-widget'

local GET_EVENTS_CMD = [[sh -c "cat %s/activity.json | jq '.[:%d] | [.[] ]]
    .. [[| {type: .type, actor: .actor, repo: .repo, action: .payload.action, issue_url: .payload.issue.html_url, ]]
    .. [[pr_url: .payload.pull_request.html_url, created_at: .created_at}]'"]]
local DOWNLOAD_AVATAR_CMD = [[sh -c "curl -n --create-dirs -o  %s/avatars/%s %s"]]
local UPDATE_EVENTS_CMD = [[sh -c "curl -s --show-error https://api.github.com/users/%s/received_events ]]
    ..[[> %s/activity.json"]]

--- Utility function to show warning messages
local function show_warning(message)
    naughty.notify{
        preset = naughty.config.presets.critical,
        title = 'GitHub Activity Widget',
        text = message}
end

--- Converts string representation of date (2020-06-02T11:25:27Z) to date
local function parse_date(date_str)
    local pattern = "(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)%Z"
    local y, m, d, h, min, sec, _ = date_str:match(pattern)

    return os.time{year = y, month = m, day = d, hour = h, min = min, sec = sec}
end

--- Converts seconds to "time ago" representation, like '1 hour ago'
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

local function generate_action_string(event)
    local action_string = event.type
    local icon = 'repo.svg'
    local link = 'http://github.com/' .. event.repo.name

    if (event.type == "PullRequestEvent") then
        action_string = event.action .. ' a pull request in'
        link = event.pr_url
        icon = 'git-pull-request.svg'
    elseif (event.type == "IssuesEvent") then
        action_string = event.action .. ' an issue in'
        link = event.issue_url
        icon = 'alert-circle.svg'
    elseif (event.type == "IssueCommentEvent") then
        action_string = event.action == 'created' and 'commented in issue' or event.action .. ' a comment in'
        link = event.issue_url
        icon = 'message-square.svg'
    elseif (event.type == "WatchEvent") then
        action_string = 'starred'
        icon = 'star.svg'
    elseif (event.type == "ForkEvent") then
        action_string = 'forked'
        icon = 'git-branch.svg'
    elseif (event.type == "CreateEvent") then
        action_string = 'created'
    end

    return { action_string = action_string, link = link, icon = icon }
end

local github_widget = wibox.widget {
    {
        {
            {
                id = 'icon',
                widget = wibox.widget.imagebox
            },
            id = "m",
            margins = 4,
            layout = wibox.container.margin
        },
        layout = wibox.layout.fixed.horizontal,
    },
    shape = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, 4)
    end,
    widget = wibox.container.background,
    set_icon = function(self, new_icon)
        self:get_children_by_id("icon")[1].image = new_icon
    end
}


local function worker(user_args)

    if not gfs.dir_readable(CACHE_DIR) then
        gfs.make_directories(CACHE_DIR)
    end

    local args = user_args or {}

    local icon = args.icon or ICONS_DIR .. 'github.png'
    local username = args.username or show_warning('No username provided')
    local number_of_events = args.number_of_events or 10

    github_widget:set_icon(icon)

    local rows = {
        layout = wibox.layout.fixed.vertical,
    }

    local rebuild_widget = function(stdout, stderr, _, _)
        if stderr ~= '' then
            show_warning(stderr)
            return
        end

        local current_time = os.time(os.date("!*t"))

        local events = json.decode(stdout)

        for i = 0, #rows do rows[i]=nil end
        for _, event in ipairs(events) do
            local path_to_avatar = CACHE_DIR .. '/avatars/' .. event.actor.id

            local avatar_img = wibox.widget {
                resize = true,
                forced_width = 40,
                forced_height = 40,
                widget = wibox.widget.imagebox
            }

            if not gfs.file_readable(path_to_avatar) then
                -- download it first
                spawn.easy_async(string.format(
                        DOWNLOAD_AVATAR_CMD,
                        CACHE_DIR,
                        event.actor.id,
                        event.actor.avatar_url), function() avatar_img:set_image(path_to_avatar) end)
            else
                avatar_img:set_image(path_to_avatar)
            end

            local action_and_link = generate_action_string(event)

            local avatar = wibox.widget {
                avatar_img,
                margins = 8,
                layout = wibox.container.margin
            }
            avatar:buttons(
                awful.util.table.join(
                        awful.button({}, 1, function()
                            spawn.with_shell('xdg-open http://github.com/' .. event.actor.login)
                            popup.visible = false
                        end)
                )
            )

            local repo_info = wibox.widget {
                {
                    markup = '<b> ' .. event.actor.display_login .. '</b> ' .. action_and_link.action_string
                        .. ' <b>' .. event.repo.name .. '</b>',
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
                        markup = to_time_ago(os.difftime(current_time, parse_date(event.created_at))),
                        widget = wibox.widget.textbox
                    },
                    spacing = 4,
                    layout = wibox.layout.fixed.horizontal,
                },
                layout = wibox.layout.align.vertical
            }
            repo_info:buttons(
                    awful.util.table.join(
                            awful.button({}, 1, function()
                                spawn.with_shell("xdg-open " .. action_and_link.link)
                                popup.visible = false
                            end)
                    )
            )

            local row = wibox.widget {
                {
                    {
                        avatar,
                        repo_info,
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

            table.insert(rows, row)
        end

        popup:setup(rows)
    end

    github_widget:buttons(
            awful.util.table.join(
                    awful.button({}, 1, function()
                        if popup.visible then
                            popup.visible = not popup.visible
                            github_widget:set_bg('#00000000')
                        else
                            github_widget:set_bg(beautiful.bg_focus)
                            spawn.easy_async(string.format(GET_EVENTS_CMD, CACHE_DIR, number_of_events),
                                function (stdout, stderr)
                                    rebuild_widget(stdout, stderr)
                                    popup:move_next_to(mouse.current_widget_geometry)
                                end)
                        end
                    end)
            )
    )

    -- Calls GitHub event API and stores response in "cache" file
    gears.timer {
        timeout   = 600,
        call_now  = true,
        autostart = true,
        callback  = function()
            spawn.easy_async(string.format(UPDATE_EVENTS_CMD, username, CACHE_DIR), function(_, stderr)
                if stderr ~= '' then show_warning(stderr) return end
            end)
        end
    }

    return github_widget
end

return setmetatable(github_widget, { __call = function(_, ...) return worker(...) end })
