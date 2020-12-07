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
local gfs = require("gears.filesystem")

local HOME_DIR = os.getenv("HOME")
local PATH_TO_AVATARS = HOME_DIR .. '/.cache/awmw/gerrit-widget/avatars/'

local GET_CHANGES_CMD = [[bash -c "curl -s -X GET -n %s/a/changes/\\?q\\=%s | tail -n +2"]]
local GET_USER_CMD = [[bash -c "curl -s -X GET -n %s/accounts/%s/ | tail -n +2"]]
local DOWNLOAD_AVATAR_CMD = [[bash -c "curl --create-dirs -o %s %s"]]

local gerrit_widget = {}

local function worker(user_args)

    local args = user_args or {}

    local icon = args.icons or HOME_DIR .. '/.config/awesome/awesome-wm-widgets/gerrit-widget/gerrit_icon.svg'
    local host = args.host or naughty.notify{
        preset = naughty.config.presets.critical,
        title = 'Gerrit Widget',
        text = 'Gerrit host is unknown'
    }
    local query = args.query or 'is:reviewer AND status:open AND NOT is:wip'
    local timeout = args.timeout or 10

    local current_number_of_reviews
    local previous_number_of_reviews = 0
    local name_dict = {}

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

    gerrit_widget = wibox.widget {
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

    local function get_name_by_user_id(user_id)
        if name_dict[user_id] == nil then
            name_dict[user_id] = {}
        end

        if name_dict[user_id].username == nil then
            name_dict[user_id].username = ''
            spawn.easy_async(string.format(GET_USER_CMD, host, user_id), function(stdout)
                local user = json.decode(stdout)
                name_dict[tonumber(user_id)].username = user.name
                if not gfs.file_readable(PATH_TO_AVATARS .. user_id) then
                    spawn.easy_async(
                        string.format(DOWNLOAD_AVATAR_CMD, PATH_TO_AVATARS .. user_id, user.avatars[1].url))
                end
            end)
            return name_dict[user_id].username
        end

        return name_dict[user_id].username
    end

    local update_widget = function(widget, stdout, _, _, _)
        local reviews = json.decode(stdout)

        current_number_of_reviews = rawlen(reviews)

        if current_number_of_reviews == 0 then
            widget:set_visible(false)
            return
        else
            widget:set_visible(true)
        end

        widget:set_visible(true)
        if current_number_of_reviews > previous_number_of_reviews then
            widget:set_unseen_review(true)
            naughty.notify{
                icon = HOME_DIR ..'/.config/awesome/awesome-wm-widgets/gerrit-widget/gerrit_icon.svg',
                title = 'New Incoming Review',
                text = reviews[1].project .. '\n' .. get_name_by_user_id(reviews[1].owner._account_id) ..
                    reviews[1].subject .. '\n',
                run = function() spawn.with_shell("xdg-open https://" .. host .. '/' .. reviews[1]._number) end
            }
        end

        previous_number_of_reviews = current_number_of_reviews
        widget:set_text(current_number_of_reviews)

        for i = 0, #rows do rows[i]=nil end
        for _, review in ipairs(reviews) do

            local row = wibox.widget {
                {
                    {
                        {
                            {
                                resize = true,
                                image = PATH_TO_AVATARS .. review.owner._account_id,
                                forced_width = 40,
                                forced_height = 40,
                                widget = wibox.widget.imagebox
                            },
                            margins = 8,
                            layout = wibox.container.margin
                        },
                        {
                            {
                                markup = '<b>' .. review.project .. '</b>',
                                align = 'center',
                                widget = wibox.widget.textbox
                            },
                            {
                                text = '  ' .. review.subject,
                                widget = wibox.widget.textbox
                            },
                            {
                                text = '  ' .. get_name_by_user_id(review.owner._account_id),
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

            row:connect_signal("button::release", function()
                spawn.with_shell("xdg-open " .. host .. '/' .. review._number)
            end)

            row:connect_signal("mouse::enter", function(c) c:set_bg(beautiful.bg_focus) end)
            row:connect_signal("mouse::leave", function(c) c:set_bg(beautiful.bg_normal) end)

            row:buttons(
                awful.util.table.join(
                    awful.button({}, 1, function()
                        spawn.with_shell("xdg-open " .. host .. '/' .. review._number)
                        popup.visible = false
                    end),
                    awful.button({}, 3, function()
                        spawn.with_shell("echo '" .. review._number .."' | xclip -selection clipboard")
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
                if popup.visible then
                    popup.visible = not popup.visible
                else
                    --local geo = mouse.current_widget_geometry
                    --if theme.calendar_placement == 'center' then
                    --    local x = geo.x + (geo.width / 2) - (popup:geometry().width / 2) -- align two widgets
                    --    popup:move_next_to({x = x, y = geo.y + 22, width = 0, height = geo.height})
                    --else
                    --    popup:move_next_to(geo)
                    --end

                    popup:move_next_to(mouse.current_widget_geometry)
                end
            end)
        )
    )

    watch(string.format(GET_CHANGES_CMD, host, query:gsub(" ", "+")), timeout, update_widget, gerrit_widget)
    return gerrit_widget
end

return setmetatable(gerrit_widget, { __call = function(_, ...) return worker(...) end })
