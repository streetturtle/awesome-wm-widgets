-------------------------------------------------
-- Jira Widget for Awesome Window Manager
-- Shows the number of currently assigned issues
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/jira-widget

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

local GET_ISSUES_CMD =
    [[bash -c "curl -s --show-error -X GET -n '%s/rest/api/2/search?%s&fields=id,assignee,summary,status'"]]
local DOWNLOAD_AVATAR_CMD = [[bash -c "curl -n --create-dirs -o  %s/.cache/awmw/jira-widget/avatars/%s %s"]]

local function show_warning(message)
    naughty.notify{
        preset = naughty.config.presets.critical,
        title = 'Jira Widget',
        text = message}
end

local jira_widget = wibox.widget {
    {
        {
            {
                {
                    id = 'c',
                    widget = wibox.widget.imagebox
                },
                {
                    id = 'd',
                    draw = function(_, _, cr, width, height)
                        cr:set_source(color(beautiful.fg_urgent))
                        cr:arc(width - height / 6, height / 6, height / 6, 0, math.pi * 2)
                        cr:fill()
                    end,
                    visible = false,
                    layout = wibox.widget.base.make_widget,
                },
                id = 'b',
                layout = wibox.layout.stack
            },
            {
                id = "txt",
                widget = wibox.widget.textbox
            },
            spacing = 4,
            layout = wibox.layout.fixed.horizontal,
        },
        margins = 4,
        layout = wibox.container.margin
    },
    shape = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, 4)
    end,
    widget = wibox.container.background,
    set_text = function(self, new_value)
        self:get_children_by_id('txt')[1]:set_text(new_value)
        --self.txt.text = new_value
    end,
    set_icon = function(self, path)
        self:get_children_by_id('c')[1]:set_image(path)
    end,
    is_everything_ok = function(self, is_ok)
        if is_ok then
            self:get_children_by_id('d')[1]:set_visible(false)
            self:get_children_by_id('c')[1]:set_opacity(1)
            self:get_children_by_id('c')[1]:emit_signal('widget:redraw_needed')
        else
            --self.txt:set_text('')
            self:get_children_by_id('txt')[1]:set_text('')
            self:get_children_by_id('d')[1]:set_visible(true)
            self:get_children_by_id('c')[1]:set_opacity(0.2)
            self:get_children_by_id('c')[1]:emit_signal('widget:redraw_needed')
        end
    end
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

local number_of_issues

local warning_shown = false
local tooltip = awful.tooltip {
    mode = 'outside',
    preferred_positions = {'bottom'},
 }

local function worker(user_args)

    local args = user_args or {}

    local icon = args.icon or
      HOME_DIR .. '/.config/awesome/awesome-wm-widgets/jira-widget/icon/jira-mark-gradient-blue.svg'
    local host = args.host or show_warning('Jira host is unknown')
    local query = args.query or 'jql=assignee=currentuser() AND resolution=Unresolved'
    local timeout = args.timeout or 600

    jira_widget:set_icon(icon)

    local separator_widget = {
        orientation = 'horizontal',
        forced_height = 1,
        color = beautiful.bg_focus,
        widget = wibox.widget.separator
    }

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

        number_of_issues = rawlen(result.issues)

        if number_of_issues == 0 then
            widget:set_visible(false)
            return
        end

        widget:set_visible(true)
        widget:set_text(number_of_issues)

        local rows = { layout = wibox.layout.fixed.vertical }

        for i = 0, #rows do rows[i]=nil end

        -- sort issues based on the status
        table.sort(result.issues, function(a,b) return a.fields.status.name > b.fields.status.name end)

        local cur_status = ''
        for _, issue in ipairs(result.issues) do

            local name
            if issue.fields.assignee.name == nil then
              name = issue.fields.assignee.displayName
            else
              name = issue.fields.assignee.name
            end

            local path_to_avatar = HOME_DIR ..'/.cache/awmw/jira-widget/avatars/' .. name

            if not gfs.file_readable(path_to_avatar) then
                spawn.easy_async(string.format(
                        DOWNLOAD_AVATAR_CMD,
                        HOME_DIR,
                        name,
                        issue.fields.assignee.avatarUrls['48x48']))
            end

            if (cur_status ~= issue.fields.status.name) then
                -- do not insert separator before first item
                if (cur_status ~= '') then
                    table.insert(rows, separator_widget)
                end

                table.insert(rows, wibox.widget {
                    {
                        {
                            markup = "<span foreground='#888888'>" .. issue.fields.status.name .. "</span>",
                            widget = wibox.widget.textbox,
                        },
                        left = 8,
                        layout = wibox.container.margin
                    },
                    bg = beautiful.bg_normal,
                    widget = wibox.container.background
                })
                cur_status = issue.fields.status.name
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
                            left = 4,
                            layout = wibox.container.margin
                        },
                        {
                            {
                                markup = '<b>' .. issue.fields.summary .. '</b>',
                                widget = wibox.widget.textbox
                            },
                            {
                                {
                                    markup = "<span foreground='#888888'>" .. issue.key .. "</span>",
                                    widget = wibox.widget.textbox
                                },
                                {
                                    markup = "<span foreground='#888888'>"
                                      .. issue.fields.assignee.displayName .. "</span>",
                                    widget = wibox.widget.textbox
                                },
                                spacing = 8,
                                layout = wibox.layout.fixed.horizontal
                            },
                            layout = wibox.layout.align.vertical
                        },
                        spacing = 8,
                        layout = wibox.layout.fixed.horizontal
                    },
                    margins = 4,
                    layout = wibox.container.margin
                },
                bg = beautiful.bg_normal,
                widget = wibox.container.background
            }

            local old_cursor, old_wibox
            row:connect_signal("mouse::enter", function(c)
                c:set_bg(beautiful.bg_focus)
                c:set_shape(function(cr, width, height)
                    gears.shape.rounded_rect(cr, width, height, 4)
                end)
                local wb = mouse.current_wibox
                old_cursor, old_wibox = wb.cursor, wb
                wb.cursor = "hand1"
            end)
            row:connect_signal("mouse::leave", function(c)
                c:set_bg(beautiful.bg_normal)
                c:set_shape(nil)
                if old_wibox then
                    old_wibox.cursor = old_cursor
                    old_wibox = nil
                end
            end)

            row:buttons(
                    awful.util.table.join(
                            awful.button({}, 1, function()
                                spawn.with_shell("xdg-open " .. host .. '/browse/' .. issue.key)
                                popup.visible = false
                                jira_widget:set_bg('#00000000')
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
                            jira_widget:set_bg('#00000000')
                            popup.visible = not popup.visible
                        else
                            jira_widget:set_bg(beautiful.bg_focus)
                            popup:move_next_to(mouse.current_widget_geometry)
                        end
                    end)
            )
    )
    watch(string.format(GET_ISSUES_CMD, host, query:gsub(' ', '+')), timeout, update_widget, jira_widget)
    return jira_widget
end

return setmetatable(jira_widget, { __call = function(_, ...) return worker(...) end })
