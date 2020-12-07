-------------------------------------------------
-- Bitbucket Widget for Awesome Window Manager
-- Shows the number of currently assigned pull requests
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/bitbucket-widget

-- @author Pavel Makhov
-- @copyright 2020 Pavel Makhov
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

local HOME_DIR = os.getenv("HOME")
local WIDGET_DIR = HOME_DIR .. '/.config/awesome/awesome-wm-widgets/bitbucket-widget/'

local GET_PRS_CMD= [[bash -c "curl -s --show-error -n ]]
    .. [['%s/2.0/repositories/%s/%s/pullrequests]]
    .. [[?fields=values.participants.approved,values.title,values.links.html,values.author.display_name,]]
    .. [[values.author.uuid,values.author.links.avatar,values.source.branch,values.destination.branch,]]
    .. [[values.comment_count,values.created_on&q=reviewers.uuid+%%3D+%%22%s%%22+AND+state+%%3D+%%22OPEN%%22']]
    .. [[ | jq '.[] '"]]
local DOWNLOAD_AVATAR_CMD = [[bash -c "curl -L -n --create-dirs -o %s/.cache/awmw/bitbucket-widget/avatars/%s %s"]]

local bitbucket_widget = wibox.widget {
    {
        {
            id = 'icon',
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
        id = "new_pr",
        widget = wibox.widget.textbox
    },
    layout = wibox.layout.fixed.horizontal,
    set_text = function(self, new_value)
        self.txt.text = new_value
    end,
    set_icon = function(self, new_value)
        self:get_children_by_id('icon')[1]:set_image(new_value)
    end
}

local function show_warning(message)
    naughty.notify{
        preset = naughty.config.presets.critical,
        title = 'Bitbucket Widget',
        text = message}
end

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

--- Converts string representation of date (2020-06-02T11:25:27Z) to date
local function parse_date(date_str)
    local pattern = "(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)%Z"
    local y, m, d, h, min, sec, _ = date_str:match(pattern)

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

local function ellipsize(text, length)
    return (text:len() > length and length > 0)
        and text:sub(0, length - 3) .. '...'
        or text
end

local function count_approves(participants)
    local res = 0
    for i = 1, #participants do
        if participants[i]['approved'] then res = res + 1 end
    end
    return res
end

local function worker(user_args)

    local args = user_args or {}

    local icon = args.icon or WIDGET_DIR .. '/bitbucket-icon-gradient-blue.svg'
    local host = args.host or show_warning('Bitbucket host is not set')
    local uuid = args.uuid or show_warning('UUID is not set')
    local workspace = args.workspace or show_warning('Workspace is not set')
    local repo_slug = args.repo_slug or show_warning('Repo slug is not set')
    local timeout = args.timeout or 60

    local current_number_of_prs

    local to_review_rows = {layout = wibox.layout.fixed.vertical}
    local my_review_rows = {layout = wibox.layout.fixed.vertical}
    local rows = {layout = wibox.layout.fixed.vertical}

    bitbucket_widget:set_icon(icon)

    local update_widget = function(widget, stdout, stderr, _, _)
        if stderr ~= '' then
            show_warning(stderr)
            return
        end

        local result = json.decode(stdout)

        current_number_of_prs = rawlen(result)

        if current_number_of_prs == 0 then
            widget:set_visible(false)
            return
        end

        widget:set_visible(true)
        widget:set_text(current_number_of_prs)

        for i = 0, #rows do rows[i]=nil end

        for i = 0, #to_review_rows do to_review_rows[i]=nil end
        table.insert(to_review_rows, {
            {
                markup = '<span size="large" color="#ffffff">PRs to review</span>',
                align = 'center',
                forced_height = 20,
                widget = wibox.widget.textbox
            },
            bg = beautiful.bg_normal,
            widget = wibox.container.background
        })

        for i = 0, #my_review_rows do my_review_rows[i]=nil end
        table.insert(my_review_rows, {
            {
                markup = '<span size="large" color="#ffffff">My PRs</span>',
                align = 'center',
                forced_height = 20,
                widget = wibox.widget.textbox
            },
            bg = beautiful.bg_normal,
            widget = wibox.container.background
        })
        local current_time = os.time(os.date("!*t"))

        for _, pr in ipairs(result) do
            local path_to_avatar = os.getenv("HOME") ..'/.cache/awmw/bitbucket-widget/avatars/' .. pr.author.uuid
            local number_of_approves = count_approves(pr.participants)

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
                                id = 'avatar',
                                margins = 8,
                                layout = wibox.container.margin
                        },
                        {
                            {
                                id = 'title',
                                markup = '<b>' .. ellipsize(pr.title, 50) .. '</b>',
                                widget = wibox.widget.textbox,
                                forced_width = 400
                            },
                            {
                                {
                                    {
                                        {
                                            text = ellipsize(pr.source.branch.name, 30),
                                            widget = wibox.widget.textbox
                                        },
                                        {
                                            text = '->',
                                            widget = wibox.widget.textbox
                                        },
                                        {
                                            text = pr.destination.branch.name,
                                            widget = wibox.widget.textbox
                                        },
                                        spacing = 8,
                                        layout = wibox.layout.fixed.horizontal
                                    },
                                    {
                                        {
                                            text = pr.author.display_name,
                                            widget = wibox.widget.textbox
                                        },
                                        {
                                            text = to_time_ago(os.difftime(current_time, parse_date(pr.created_on))),
                                            widget = wibox.widget.textbox
                                        },
                                        spacing = 8,
                                        expand = 'none',
                                        layout = wibox.layout.fixed.horizontal
                                    },
                                    forced_width = 285,
                                    layout = wibox.layout.fixed.vertical
                                },
                                {
                                    {
                                        {
                                            image = WIDGET_DIR .. '/check.svg',
                                            resize = false,
                                            widget = wibox.widget.imagebox
                                        },
                                        {
                                            text = number_of_approves,
                                            widget = wibox.widget.textbox
                                        },
                                        layout = wibox.layout.fixed.horizontal
                                    },
                                    {
                                        {
                                            image = WIDGET_DIR .. '/message-circle.svg',
                                            resize = false,
                                            widget = wibox.widget.imagebox
                                        },
                                        {
                                            text = pr.comment_count,
                                            widget = wibox.widget.textbox
                                        },
                                        layout = wibox.layout.fixed.horizontal
                                    },
                                    layout = wibox.layout.fixed.vertical
                                },
                                layout = wibox.layout.fixed.horizontal
                            },

                            spacing = 8,
                            layout = wibox.layout.fixed.vertical
                        },
                        spacing = 8,
                        layout = wibox.layout.fixed.horizontal
                    },
                    margins = 8,
                    layout = wibox.container.margin
                },
                bg = beautiful.bg_normal,
                widget = wibox.container.background
            }

            if not gfs.file_readable(path_to_avatar) then
                local cmd = string.format(DOWNLOAD_AVATAR_CMD, HOME_DIR, pr.author.uuid, pr.author.links.avatar.href)
                spawn.easy_async(cmd, function() row:get_children_by_id('avatar')[1]:set_image(path_to_avatar) end)
            end


            row:connect_signal("mouse::enter", function(c) c:set_bg(beautiful.bg_focus) end)
            row:connect_signal("mouse::leave", function(c) c:set_bg(beautiful.bg_normal) end)

            row:get_children_by_id('title')[1]:buttons(
                    awful.util.table.join(
                            awful.button({}, 1, function()
                                spawn.with_shell("xdg-open " .. pr.links.html.href)
                                popup.visible = false
                            end)
                    )
            )
            row:get_children_by_id('avatar')[1]:buttons(
                awful.util.table.join(
                    awful.button({}, 1, function()
                        spawn.with_shell(
                            string.format('xdg-open "https://bitbucket.org/%s/%s/pull-requests?state=OPEN&author=%s"',
                            workspace, repo_slug, pr.author.uuid)
                        )
                        popup.visible = false
                    end)
                )
            )

            local old_cursor, old_wibox
            row:get_children_by_id('title')[1]:connect_signal("mouse::enter", function()
                local wb = mouse.current_wibox
                old_cursor, old_wibox = wb.cursor, wb
                wb.cursor = "hand1"
            end)
            row:get_children_by_id('title')[1]:connect_signal("mouse::leave", function()
                if old_wibox then
                    old_wibox.cursor = old_cursor
                    old_wibox = nil
                end
            end)

            row:get_children_by_id('avatar')[1]:connect_signal("mouse::enter", function()
                local wb = mouse.current_wibox
                old_cursor, old_wibox = wb.cursor, wb
                wb.cursor = "hand1"
            end)
            row:get_children_by_id('avatar')[1]:connect_signal("mouse::leave", function()
                if old_wibox then
                    old_wibox.cursor = old_cursor
                    old_wibox = nil
                end
            end)

            if (pr.author.uuid == '{' .. uuid .. '}') then
                table.insert(my_review_rows, row)
            else
                table.insert(to_review_rows, row)
            end
        end

        table.insert(rows, to_review_rows)
        if (#my_review_rows > 1) then
            table.insert(rows, my_review_rows)
        end
        popup:setup(rows)
    end

    bitbucket_widget:buttons(
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

    watch(string.format(GET_PRS_CMD, host, workspace, repo_slug, uuid, uuid),
            timeout, update_widget, bitbucket_widget)
    return bitbucket_widget
end

return setmetatable(bitbucket_widget, { __call = function(_, ...) return worker(...) end })
