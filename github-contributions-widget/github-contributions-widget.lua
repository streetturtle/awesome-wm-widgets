-------------------------------------------------
-- Github Contributions Widget for Awesome Window Manager
-- Shows the contributions graph
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/github-contributions-widget

-- @author Pavel Makhov
-- @copyright 2020 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local naughty = require("naughty")
local wibox = require("wibox")
local widget_themes = require("awesome-wm-widgets.github-contributions-widget.themes")

local GET_CONTRIBUTIONS_CMD = [[bash -c "curl -s https://github-contributions.now.sh/api/v1/%s | jq -r '[.contributions[] | select ( .date | strptime(\"%%Y-%%m-%%d\") | mktime < now)][:%s]| .[].color'"]]

local github_contributions_widget = wibox.widget{
    reflection = {
        horizontal = true,
        vertical = true,
    },
    widget = wibox.container.mirror
}

local function show_warning(message)
    naughty.notify{
        preset = naughty.config.presets.critical,
        title = 'Github Contributions Widget',
        text = message}
end

local function worker(args)

    local args = args or {}

    local username = args.username or 'streetturtle'
    local days = args.days or 365
    local color_of_empty_cells = args.color_of_empty_cells
    local with_border = args.with_border
    local margin_top = args.margin_top or 1
    local theme = args.theme or 'standard'

    if widget_themes[theme] == nil then
        show_warning('Theme ' .. theme .. ' does not exist')
        theme = 'standard'
    end

    if with_border == nil then with_border = true end

    local function hex2rgb(hex)
        if color_of_empty_cells ~= nil and hex == widget_themes[theme]['color_calendar_graph_day_bg'] then
            hex = color_of_empty_cells
        end
        hex = tostring(hex):gsub('#','')
        return tonumber('0x' .. hex:sub(1, 2)),
                tonumber('0x' .. hex:sub(3, 4)),
                tonumber('0x' .. hex:sub(5, 6))
    end

    local function get_square(color)
        local r, g, b = hex2rgb(color)

        return wibox.widget{
            fit = function(self, context, width, height)
                return 3, 3
            end,
            draw = function(self, context, cr, width, height)
                cr:set_source_rgb(r/255, g/255, b/255)
                cr:rectangle(0, 0, with_border and 2 or 3, with_border and 2 or 3)
                cr:fill()
            end,
            layout = wibox.widget.base.make_widget
        }
    end

    local col = {layout = wibox.layout.fixed.vertical}
    local row = {layout = wibox.layout.fixed.horizontal}
    local a = 5 - os.date('%w')
    for i = 0, a do
        table.insert(col, get_square(color_of_empty_cells))
    end

    local update_widget = function(widget, stdout, _, _, _)
        for colors in stdout:gmatch("[^\r\n]+") do
            if a%7 == 0 then
                table.insert(row, col)
                col = {layout = wibox.layout.fixed.vertical}
            end
            table.insert(col, get_square(widget_themes[theme][colors:match('var%(%-%-(.*)%)'):gsub('-', '_')]))
            a = a + 1
        end
        github_contributions_widget:setup(
            {
                row,
                top = margin_top,
                layout = wibox.container.margin
            }
        )
    end

    awful.spawn.easy_async(string.format(GET_CONTRIBUTIONS_CMD, username, days),
        function(stdout, stderr)
            update_widget(github_contributions_widget, stdout)
        end)

    return github_contributions_widget
end

return setmetatable(github_contributions_widget, { __call = function(_, ...) return worker(...) end })
