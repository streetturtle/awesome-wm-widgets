-------------------------------------------------
-- Github Contributions Widget for Awesome Window Manager
-- Shows the contributions graph
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/github-contributions-widget

-- @author Pavel Makhov
-- @copyright 2020 Pavel Makhov
-------------------------------------------------

local awful         = require("awful")
local naughty       = require("naughty")
local wibox         = require("wibox")
local gears         = require("gears")
local widget_themes = require("awesome-wm-widgets.github-contributions-widget.themes")

local HOME_DIR = os.getenv("HOME")
local ICONS_DIR = HOME_DIR .. '/.config/awesome/icons/'

local GET_CONTRIBUTIONS_CMD = [[bash -c "curl -s https://github-contributions.vercel.app/api/v1/%s]]
    .. [[ | jq -r '[.contributions[] ]]
    .. [[ | select ( .date | strptime(\"%%Y-%%m-%%d\") | mktime < now)][:%s] ]]
    .. [[ | .[] | .intensity + \" \" + .date + \" \" + (.count|tostring)'"]]

local contributions_widget = wibox.widget{
    reflection = {
        horizontal = true,
        vertical = true,
    },
    widget = wibox.container.mirror
}

local github_textwidget = wibox.widget {
    align  = 'right',
    valign = 'bottom',
    opacity = .5,
    font = "Arial 8",
    widget = wibox.widget.textbox
}

local github_imagewidget = wibox.widget {
    image   = ICONS_DIR .. "logo-github.png",
    resize  = true,
    opacity = .5,
    halign  = "center",
    widget  = wibox.widget.imagebox
}

local github_contributions_widget = wibox.widget {
    contributions_widget,
    github_imagewidget,
    github_textwidget,
    layout = wibox.layout.stack
}

local function show_warning(message)
    naughty.notify{
        preset = naughty.config.presets.critical,
        title = 'Github Contributions Widget',
        text = message}
end

local function worker(args)

    args = args or {}
    args.username             = args.username    or 'cobacdavid'
    args.days                 = args.days        or 365
    args.square_size          = args.square_size or 4
    args.color_of_empty_cells = args.color_of_empty_cells
    args.with_border          = args.with_border
    args.margin_top           = args.margin_top  or 1
    args.theme                = args.theme       or 'standard'

    if widget_themes[args.theme] == nil then
        show_warning('Theme ' .. args.theme .. ' does not exist')
        args.theme = 'standard'
    end

    if args.with_border == nil then args.with_border = true end

    local function get_square(date, count, color)
        if args.color_of_empty_cells ~= nil and
            color == widget_themes[args.theme][0] then
            color = args.color_of_empty_cells
        end

        local square = wibox.widget{
            fit = function()
                return args.square_size, args.square_size
            end,
            draw = function(_, _, cr, _, _)
                cr:set_source(gears.color(color))
                cr:rectangle(
                    0,
                    0,
                    args.with_border and args.square_size-1 or args.square_size,
                    args.with_border and args.square_size-1 or args.square_size
                )
                cr:fill()
            end,
            layout = wibox.widget.base.make_widget
        }

        if date ~= nil then
            local year, month, day = date:match("(%d+)%-(%d+)%-(%d+)")
            date = os.date("%a %d %b %Y",
                           os.time({year=year, month=month, day=day}))
            local contrib = (count == "0" or count == "1") and "contribution" or "contributions"
            awful.tooltip {
                text = string.format("%s: %s %s", date, count, contrib),
                mode = "mouse"
            }:add_to_object(square)
        end

        return square
    end

    local col = {layout = wibox.layout.fixed.vertical}
    local row = {layout = wibox.layout.fixed.horizontal}
    local day_idx = 6 - os.date('%w')
    for _ = 1, day_idx do
        table.insert(col, get_square(nil, 0, args.color_of_empty_cells))
    end

    local update_widget = function(_, stdout, _, _, _)
        for day_value in stdout:gmatch("[^\r\n]+") do
            local intensity, date, count = day_value:match("(%d+)%s(.+)%s(%d+)")
            if day_idx %7 == 0 then
                table.insert(row, col)
                col = {layout = wibox.layout.fixed.vertical}
            end
            table.insert(col, get_square(
                             date,
                             count,
                             widget_themes[args.theme][tonumber(intensity)]                             
            ))
            day_idx = day_idx + 1
        end
        contributions_widget:setup(
            {
                row,
                top = args.margin_top,
                layout = wibox.container.margin
            }
        )
    end

    awful.spawn.easy_async(string.format(GET_CONTRIBUTIONS_CMD, args.username, args.days),
        function(stdout)
            update_widget(github_contributions_widget, stdout)
        end)

    github_textwidget:set_markup("<b>" .. args.username .. "</b>")
    github_contributions_widget:add_button(
        awful.button({}, 1, function()
                awful.spawn(browser .. " https://github.com/" .. args.username)
        end)
    )
    
    return github_contributions_widget
end

return setmetatable(github_contributions_widget, { __call = function(_, args) return worker(args) end })
