-------------------------------------------------
-- Gitlab Widget for Awesome Window Manager
-- Shows the number of currently assigned merge requests
-- and information about them
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/gitlab-widget

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
local color = require("gears.color")

local HOME_DIR = os.getenv("HOME")
local WIDGET_DIR = HOME_DIR .. '/.config/awesome/awesome-wm-widgets/gitlab-widget/'
local GET_PRS_CMD= [[sh -c "curl -s --connect-timeout 5 --show-error --header 'PRIVATE-TOKEN: %s']]
    ..[[ '%s/api/v4/merge_requests?state=opened'"]]
local DOWNLOAD_AVATAR_CMD = [[sh -c "curl -L --create-dirs -o %s/.cache/awmw/gitlab-widget/avatars/%s %s"]]

local gitlab_widget = wibox.widget {
    {
        {
            {
                id = 'icon',
                widget = wibox.widget.imagebox
            },
            {
                id = 'error_marker',
                draw = function(_, _, cr, width, height)
                    cr:set_source(color(beautiful.fg_urgent))
                    cr:arc(width - height/6, height/6, height/6, 0, math.pi*2)
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
    layout = wibox.layout.fixed.horizontal,
    set_text = function(self, new_value)
        self.txt.text = new_value
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
        title = 'Gitlab Widget',
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

local warning_shown = false
local tooltip = awful.tooltip {
    mode = 'outside',
    preferred_positions = {'bottom'},
 }

local function worker(user_args)

    local args = user_args or {}

    local icon = args.icon or WIDGET_DIR .. '/icons/gitlab-icon.svg'
    local access_token = args.access_token or show_warning('API Token is not set')
    local host = args.host or show_warning('Gitlab host is not set')
    local timeout = args.timeout or 60

    local current_number_of_prs

    local to_review_rows = {layout = wibox.layout.fixed.vertical}
    local my_review_rows = {layout = wibox.layout.fixed.vertical}
    local rows = {layout = wibox.layout.fixed.vertical}

    gitlab_widget:set_icon(icon)

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
            local path_to_avatar = os.getenv("HOME") ..'/.cache/awmw/gitlab-widget/avatars/' .. pr.author.id

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
                                            text = pr.source_branch,
                                            widget = wibox.widget.textbox
                                        },
                                        {
                                            text = '->',
                                            widget = wibox.widget.textbox
                                        },
                                        {
                                            text = pr.target_branch,
                                            widget = wibox.widget.textbox
                                        },
                                        spacing = 8,
                                        layout = wibox.layout.fixed.horizontal
                                    },
                                    {
                                        {
                                            text = pr.author.name,
                                            widget = wibox.widget.textbox
                                        },
                                        {
                                            text = to_time_ago(os.difftime(current_time, parse_date(pr.created_at))),
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
                                            -- image = number_of_approves > 0 and WIDGET_DIR .. '/check.svg' or '',
                                            image = WIDGET_DIR .. '/icons/check.svg',
                                            resize = false,
                                            widget = wibox.widget.imagebox
                                        },
                                        {
                                            text = pr.upvotes,
                                            widget = wibox.widget.textbox
                                        },
                                        layout = wibox.layout.fixed.horizontal
                                    },
                                    {
                                        {
                                            image = WIDGET_DIR .. '/icons/message-circle.svg',
                                            resize = false,
                                            widget = wibox.widget.imagebox
                                        },
                                        {
                                            text = pr.user_notes_count,
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
                spawn.easy_async(string.format(
                        DOWNLOAD_AVATAR_CMD,
                        HOME_DIR,
                        pr.author.id,
                        pr.author.avatar_url), function()
                            row:get_children_by_id('avatar')[1]:set_image(path_to_avatar)
                        end)
            end

            row:connect_signal("mouse::enter", function(c) c:set_bg(beautiful.bg_focus) end)
            row:connect_signal("mouse::leave", function(c) c:set_bg(beautiful.bg_normal) end)

            row:get_children_by_id('title')[1]:buttons(
                    awful.util.table.join(
                            awful.button({}, 1, function()
                                spawn.with_shell("xdg-open " .. pr.web_url)
                                popup.visible = false
                            end)
                    )
            )
            row:get_children_by_id('avatar')[1]:buttons(
                    awful.util.table.join(
                            awful.button({}, 1, function()
                                spawn.with_shell("xdg-open " .. pr.author.web_url)
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
        if (#my_review_rows > 1) then
            table.insert(rows, my_review_rows)
        end
        popup:setup(rows)
    end

    gitlab_widget:buttons(
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

    watch(string.format(GET_PRS_CMD, access_token, host),
        -- string.format(GET_PRS_CMD, host, workspace, repo_slug, uuid, uuid),
            timeout, update_widget, gitlab_widget)
    return gitlab_widget
end

return setmetatable(gitlab_widget, { __call = function(_, ...) return worker(...) end })
