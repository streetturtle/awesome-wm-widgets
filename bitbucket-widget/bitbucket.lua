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

local GET_PRS_CMD= [[bash -c "curl -s --show-error -n '%s/2.0/repositories/%s/%s/pullrequests?fields=values.title,values.links.html,values.author.display_name,values.author.uuid,values.author.links.avatar,values.source.branch,values.destination.branch&q=%%28author.uuid+%%3D+%%22%s%%22+OR+reviewers.uuid+%%3D+%%22%s%%22+%%29+AND+state+%%3D+%%22OPEN%%22' | jq '.[] | unique'"]]
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

local function worker(args)

    local args = args or {}

    local icon = args.icon or HOME_DIR .. '/.config/awesome/awesome-wm-widgets/bitbucket-widget/bitbucket-icon-gradient-blue.svg'
    local host = args.host or show_warning('Bitbucket host is not set')
    local uuid = args.uuid or show_warning('UUID is not set')
    local workspace = args.workspace or show_warning('Workspace is not set')
    local repo_slug = args.repo_slug or show_warning('Repo slug is not set')

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

        for _, pr in ipairs(result) do
            local path_to_avatar = os.getenv("HOME") ..'/.cache/awmw/bitbucket-widget/avatars/' .. pr.author.uuid

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
                                markup = '<b>' .. pr.title .. '</b>',
                                widget = wibox.widget.textbox
                            },
                            {
                                {
                                    text = pr.source.branch.name,
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
                                text = pr.author.display_name,
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
                bg = beautiful.bg_normal,
                widget = wibox.container.background
            }

            if not gfs.file_readable(path_to_avatar) then
                spawn.easy_async(string.format(
                        DOWNLOAD_AVATAR_CMD,
                        HOME_DIR,
                        pr.author.uuid,
                        pr.author.links.avatar.href), function() row:get_children_by_id('avatar')[1]:set_image(path_to_avatar) end)
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
                                spawn.with_shell(string.format('xdg-open "https://bitbucket.org/%s/%s/pull-requests?state=OPEN&author=%s"', workspace, repo_slug, pr.author.uuid))
                                popup.visible = false
                            end)
                    )
            )

            local old_cursor, old_wibox
            row:get_children_by_id('title')[1]:connect_signal("mouse::enter", function(c)
                local wb = mouse.current_wibox
                old_cursor, old_wibox = wb.cursor, wb
                wb.cursor = "hand1"
            end)
            row:get_children_by_id('title')[1]:connect_signal("mouse::leave", function(c)
                if old_wibox then
                    old_wibox.cursor = old_cursor
                    old_wibox = nil
                end
            end)

            local old_cursor, old_wibox
            row:get_children_by_id('avatar')[1]:connect_signal("mouse::enter", function(c)
                local wb = mouse.current_wibox
                old_cursor, old_wibox = wb.cursor, wb
                wb.cursor = "hand1"
            end)
            row:get_children_by_id('avatar')[1]:connect_signal("mouse::leave", function(c)
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
            60, update_widget, bitbucket_widget)
    return bitbucket_widget
end

return setmetatable(bitbucket_widget, { __call = function(_, ...) return worker(...) end })
