-------------------------------------------------
-- Gerrit Widget for Awesome Window Manager
-- Shows the number of currently assigned reviews
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/gerrit-widget

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
    local current_number_of_reviews
    local previous_number_of_reviews = 0

    local rows = {
        {
            widget = wibox.widget.textbox
        },
        layout = wibox.layout.fixed.vertical,
    }

    local popup = awful.popup{
        visible = true,
        ontop = true,
        visible = false,
        shape = gears.shape.rounded_rect,
        border_width = 1,
        preferred_positions = top,
        widget = {}
    }

    gerrit_widget = wibox.widget {
        {
            {
                image = os.getenv("HOME") .. '/.config/awesome/awesome-wm-widgets/gerrit-widget/gerrit_icon.svg',
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
            if is_new_review then
                self.new_rev.text = '*'
            else
                self.new_rev.text = ''
            end
        end
    }

    local function get_name_by_id(id)
        res = name_dict[id]
        if res == nil then
            res = ''
            spawn.easy_async(string.format(GET_USERNAME_CMD, host, id), function(stdout, stderr, reason, exit_code)
                name_dict[tonumber(id)] = string.gsub(stdout, "\n", "")
            end)
        end
        return res
    end

    local update_graphic = function(widget, stdout, _, _, _)
        reviews = json.decode(stdout)

        current_number_of_reviews = rawlen(reviews)

        if current_number_of_reviews > previous_number_of_reviews then
            widget:set_unseen_review(true)
            naughty.notify{
                icon = os.getenv("HOME") ..'/.config/awesome/awesome-wm-widgets/gerrit-widget/gerrit_icon.svg',
                title = 'New Incoming Review',
                text = reviews[1].project .. '\n' .. get_name_by_id(reviews[1].owner._account_id) .. reviews[1].subject ..'\n',
                run = function() spawn.with_shell("google-chrome https://" .. host .. '/' .. reviews[1]._number) end
            }
        end

        previous_number_of_reviews = current_number_of_reviews
        widget:set_text(current_number_of_reviews)

        count = #rows
        for i=0, count do rows[i]=nil end
        for _, review in ipairs(reviews) do
            local row = wibox.widget {
                {
                    {
                        {
                            text = review.project .. ' / ' .. get_name_by_id(review.owner._account_id),
                            widget = wibox.widget.textbox
                        },
                        {
                            text = review.subject,
                            widget = wibox.widget.textbox
                        },
                        layout = wibox.layout.align.vertical
                    },
                    margins = 5,
                    layout = wibox.container.margin
                },
                widget = wibox.container.background
            }

            row:connect_signal("button::release", function(_, _, _, button)
                spawn.with_shell("google-chrome https://" .. host .. '/' .. review._number)
            end)

            row:connect_signal("mouse::enter", function(c)
                c:set_bg(beautiful.bg_focus)
            end)

            row:connect_signal("mouse::leave", function(c)
                c:set_bg(beautiful.bg_normal)
            end)

            row:buttons(
                awful.util.table.join(
                    awful.button({}, 1, function()
                        spawn.with_shell("google-chrome https://" .. host .. '/' .. review._number)
                        popup.visible = false
                    end),
                    awful.button({}, 3, function()
                        spawn.with_shell("echo 'git-review -d " .. review._number .."' | xclip -selection clipboard")
                        popup.visible = false
                    end)
                )
            )

            table.insert(rows, row)
        end

        popup:setup(rows)
    end

    gerrit_widget:buttons(
        awful.util.table.join(
            awful.button({}, 1, function()
                gerrit_widget:set_unseen_review(false)
                awful.placement.top_right(popup, { margins = { top = 25, right = 10}, parent = awful.screen.focused() })
                popup.visible = not popup.visible
            end)
        )
    )

    watch(string.format(GET_CHANGES_CMD, host, query:gsub(" ", "+")), 5, update_graphic, gerrit_widget)
    return gerrit_widget
end

return setmetatable(gerrit_widget, { __call = function(_, ...) return worker(...) end })
