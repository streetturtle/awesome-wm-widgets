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

local GET_PRS_CMD= [[bash -c "curl -s -n '%s/2.0/repositories/%s/%s/pullrequests?fields=values.title,values.links.html,values.author.display_name,values.author.account_id,values.author.links.avatar&q=reviewers.account_id+%%3D+%%22%s%%22+AND+state+%%3D+%%22OPEN%%22'"]]
local DOWNLOAD_AVATAR_CMD = [[bash -c "curl -n --create-dirs -o %s/.cache/awmw/bitbucket-widget/avatars/%s %s"]]

local bitbucket_widget = {}

local function show_warning(message)
    naughty.notify{
        preset = naughty.config.presets.critical,
        title = 'Bitbucket Widget',
        text = message}
end

local function worker(args)

    local args = args or {}

    local icon = args.icon or HOME_DIR .. '/.config/awesome/awesome-wm-widgets/bitbucket-widget/bitbucket-icon-gradient-blue.svg'
    local host = args.host or show_warning('Bitbucket host is unknown')
    local account_id = args.account_id or show_warning('Account Id is not set')
    local workspace = args.workspace or show_warning('Workspace is not set')
    local repo_slug = args.repo_slug or show_warning('Repo slug is not set')

    local current_number_of_prs

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

    bitbucket_widget = wibox.widget {
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
            id = "new_pr",
            widget = wibox.widget.textbox
        },
        layout = wibox.layout.fixed.horizontal,
        set_text = function(self, new_value)
            self.txt.text = new_value
        end
    }

    local update_widget = function(widget, stdout, stderr, _, _)
        if stderr ~= '' then show_warning(stderr) end

        local result = json.decode(stdout)

        current_number_of_prs = rawlen(result.values)

        if current_number_of_prs == 0 then
            widget:set_visible(false)
            return
        end

        widget:set_visible(true)
        widget:set_text(current_number_of_prs)

        for i = 0, #rows do rows[i]=nil end
        for _, pr in ipairs(result.values) do
            local path_to_avatar = os.getenv("HOME") ..'/.cache/awmw/bitbucket-widget/avatars/' .. pr.author.account_id

            if not gfs.file_readable(path_to_avatar) then
                spawn.easy_async(string.format(
                        DOWNLOAD_AVATAR_CMD,
                        HOME_DIR,
                        pr.author.account_id,
                        pr.author.links.avatar.href))
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
                                markup = '<b>' .. pr.title .. '</b>',
                                widget = wibox.widget.textbox
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
                widget = wibox.container.background
            }

            row:connect_signal("mouse::enter", function(c) c:set_bg(beautiful.bg_focus) end)
            row:connect_signal("mouse::leave", function(c) c:set_bg(beautiful.bg_normal) end)

            row:buttons(
                    awful.util.table.join(
                            awful.button({}, 1, function()
                                spawn.with_shell("xdg-open " .. pr.links.html.href)
                                popup.visible = false
                            end)
                    )
            )

            table.insert(rows, row)
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

    watch(string.format(GET_PRS_CMD, host, workspace, repo_slug, account_id),
            10, update_widget, bitbucket_widget)
    return bitbucket_widget
end

return setmetatable(bitbucket_widget, { __call = function(_, ...) return worker(...) end })
