-------------------------------------------------
-- GitHub Widget for Awesome Window Manager
-- Shows the number of currently assigned merge requests
-- and information about them
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/github-prs-widget

-- @author Pavel Makhov
-- @copyright 2021 Pavel Makhov
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
local color = require("gears.color")

local HOME_DIR = os.getenv("HOME")
local WIDGET_DIR = HOME_DIR .. '/.config/awesome/awesome-wm-widgets/github-prs-widget/'
local ICONS_DIR = WIDGET_DIR .. 'icons/'

local AVATARS_DIR = HOME_DIR .. '/.cache/awmw/github-widget/avatars/'
local DOWNLOAD_AVATAR_CMD = [[sh -c "curl -L --create-dirs -o ''\\]] .. AVATARS_DIR .. [[%s %s"]]

local GET_PRS_CMD = "gh api -X GET search/issues "
        .. "-f 'q=review-requested:%s is:unmerged is:open' "
        .. "-f per_page=30 "
        .. "--jq '[.items[] | {url,repository_url,title,html_url,comments,assignees,user,created_at,draft}]'"

local github_widget = wibox.widget {
    {
        {
            {
                {
                    {
                        id = 'icon',
                        widget = wibox.widget.imagebox
                    },
                    {
                        id = 'error_marker',
                        draw = function(_, _, cr, width, height)
                            cr:set_source(color('#BF616A'))
                            cr:arc(width - height / 6, height / 6, height / 6, 0, math.pi * 2)
                            cr:fill()
                        end,
                        visible = false,
                        layout = wibox.widget.base.make_widget,
                    },
                    layout = wibox.layout.stack
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
            spacing = 4,
            layout = wibox.layout.fixed.horizontal,
        },
        left = 4,
        right = 4,
        widget = wibox.container.margin
    },
    shape = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, 4)
    end,
    widget = wibox.container.background,
    set_text = function(self, new_value)
        self:get_children_by_id('txt')[1]:set_text(new_value)
    end,
    set_icon = function(self, new_value)
        self:get_children_by_id('icon')[1]:set_image(new_value)
    end,
    is_everything_ok = function(self, is_ok)
        if is_ok then
            self:get_children_by_id('error_marker')[1]:set_visible(false)
            self:get_children_by_id('icon')[1]:set_opacity(1)
            self:get_children_by_id('icon')[1]:emit_signal('widget:redraw_needed')
        else
            self.txt:set_text('')
            self:get_children_by_id('error_marker')[1]:set_visible(true)
            self:get_children_by_id('icon')[1]:set_opacity(0.2)
            self:get_children_by_id('icon')[1]:emit_signal('widget:redraw_needed')
        end
    end
}

local function show_warning(message)
    naughty.notify{
        preset = naughty.config.presets.critical,
        title = 'GitHub PRs Widget',
        text = message}
end

local popup = awful.popup{
    ontop = true,
    visible = false,
    shape = gears.shape.rounded_rect,
    border_width = 1,
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

local warning_shown = false
local tooltip = awful.tooltip {
    mode = 'outside',
    preferred_positions = {'bottom'},
}

local config = {}

config.reviewer = nil

config.bg_normal = '#aaaaaa'
config.bg_focus = '#ffffff'


local function worker(user_args)

    local args = user_args or {}

    -- Setup config for the widget instance.
    -- The `_config` table will keep the first existing value after checking
    -- in this order: user parameter > beautiful > module default
    local _config = {}
    for prop, value in pairs(config) do
        _config[prop] = args[prop] or beautiful[prop] or value
    end

    local icon = args.icon or ICONS_DIR .. 'git-pull-request.svg'
    local reviewer = args.reviewer
    local timeout = args.timeout or 60

    local current_number_of_prs

    local to_review_rows = {layout = wibox.layout.fixed.vertical}
    local rows = {layout = wibox.layout.fixed.vertical}

    github_widget:set_icon(icon)

    local update_widget = function(widget, stdout, stderr, _, _)

        if stderr ~= '' then
            if not warning_shown then
                show_warning(stderr)
                warning_shown = true
                widget:is_everything_ok(false)
                tooltip:add_to_object(widget)

                widget:connect_signal('mouse::enter', function()
                    tooltip.text = stderr
                end)
            end
            return
        end

        warning_shown = false
        tooltip:remove_from_object(widget)
        widget:is_everything_ok(true)

        local prs = json.decode(stdout)

        current_number_of_prs = #prs

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
            bg = _config.bg_normal,
            widget = wibox.container.background
        })

        local current_time = os.time(os.date("!*t"))

        for _, pr in ipairs(prs) do
            local path_to_avatar = AVATARS_DIR .. pr.user.id
            local index = string.find(pr.repository_url, "/[^/]*$")
            local repo = string.sub(pr.repository_url, index + 1)

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
                            margins = 4,
                            layout = wibox.container.margin
                        },
                        {
                            {
                                id = 'title',
                                markup = '<b>' .. ellipsize(pr.title, 60) .. '</b>',
                                widget = wibox.widget.textbox,
                                forced_width = 400
                            },
                            {
                                {
                                    {
                                        {
                                            image = ICONS_DIR .. 'book.svg',
                                            forced_width = 12,
                                            forced_height = 12,
                                            resize = true,
                                            widget = wibox.widget.imagebox
                                        },
                                        {
                                            text = repo,
                                            widget = wibox.widget.textbox
                                        },
                                        spacing = 4,
                                        expand = 'none',
                                        layout = wibox.layout.fixed.horizontal
                                    },
                                    {
                                        {
                                            image = ICONS_DIR .. 'user.svg',
                                            forced_width = 12,
                                            forced_height = 12,
                                            resize = true,
                                            widget = wibox.widget.imagebox
                                        },
                                        {
                                            text = pr.user.login,
                                            widget = wibox.widget.textbox
                                        },
                                        spacing = 4,
                                        expand = 'none',
                                        layout = wibox.layout.fixed.horizontal
                                    },
                                    spacing = 8,
                                    expand = 'none',
                                    layout = wibox.layout.fixed.horizontal
                                },
                                {
                                    {
                                        {
                                            image = ICONS_DIR .. 'user.svg',
                                            forced_width = 12,
                                            forced_height = 12,
                                            resize = true,
                                            widget = wibox.widget.imagebox
                                        },
                                        {
                                            text = to_time_ago(os.difftime(current_time, parse_date(pr.created_at))),
                                            widget = wibox.widget.textbox
                                        },
                                        spacing = 4,
                                        expand = 'none',
                                        layout = wibox.layout.fixed.horizontal

                                    },
                                    {
                                        {
                                            image = ICONS_DIR .. 'message-square.svg',
                                            forced_width = 12,
                                            forced_height = 12,
                                            resize = true,
                                            widget = wibox.widget.imagebox
                                        },
                                        {
                                            text = pr.comments,
                                            widget = wibox.widget.textbox
                                        },
                                        spacing = 4,
                                        expand = 'none',
                                        layout = wibox.layout.fixed.horizontal

                                    },
                                    spacing = 8,
                                    layout = wibox.layout.fixed.horizontal
                                },
                                layout = wibox.layout.fixed.vertical
                            },
                            spacing = 4,
                            layout = wibox.layout.fixed.vertical
                        },
                        spacing = 8,
                        layout = wibox.layout.fixed.horizontal
                    },
                    margins = 8,
                    layout = wibox.container.margin
                },
                bg = _config.bg_normal,
                widget = wibox.container.background
            }

            if not gfs.file_readable(path_to_avatar) then
                spawn.easy_async(string.format(
                        DOWNLOAD_AVATAR_CMD,
                        pr.user.id,
                        pr.user.avatar_url), function()
                    row:get_children_by_id('avatar')[1]:set_image(path_to_avatar)
                end)
            end

            row:connect_signal("mouse::enter", function(c) c:set_bg(_config.bg_focus) end)
            row:connect_signal("mouse::leave", function(c) c:set_bg(_config.bg_normal) end)

            row:get_children_by_id('title')[1]:buttons(
                    awful.util.table.join(
                            awful.button({}, 1, function()
                                spawn.with_shell("xdg-open " .. pr.html_url)
                                popup.visible = false
                            end)
                    )
            )
            row:get_children_by_id('avatar')[1]:buttons(
                    awful.util.table.join(
                            awful.button({}, 1, function()
                                spawn.with_shell("xdg-open " .. pr.user.html_url)
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

            table.insert(to_review_rows, row)
        end

        table.insert(rows, to_review_rows)
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
                            popup:move_next_to(mouse.current_widget_geometry)
                        end
                    end)
            )
    )

    watch(string.format(GET_PRS_CMD, reviewer),
            timeout, update_widget, github_widget)

    return github_widget
end

return setmetatable(github_widget, { __call = function(_, ...) return worker(...) end })
