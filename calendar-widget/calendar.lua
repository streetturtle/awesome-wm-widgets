-------------------------------------------------
-- Calendar Widget for Awesome Window Manager
-- Shows the current month and supports scroll up/down to switch month
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/calendar-widget

-- @author Pavel Makhov
-- @copyright 2019 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local beautiful = require("beautiful")
local wibox = require("wibox")
local gears = require("gears")

local calendar_widget = {}

local styles = {}
local function rounded_shape(size)
    return function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, size)
    end
end

styles.month = {
    padding = 4,
    bg_color = '#2E3440',
    border_width = 0,
}

styles.normal = {
    markup = function(t) return t end,
    shape = rounded_shape(4)
}

styles.focus = {
    fg_color = '#000000',
    bg_color = '#88C0D0',
    markup = function(t) return '<b>' .. t .. '</b>' end,
    shape = rounded_shape(4)
}

styles.header = {
    fg_color = '#E5E9F0',
    markup = function(t) return '<b>' .. t .. '</b>' end,
    bg_color = '#2E3440'
}

styles.weekday = {
    fg_color = '#88C0D0',
    markup = function(t) return '<b>' .. t .. '</b>' end,
    bg_color = '#2E3440',
}

local function decorate_cell(widget, flag, date)
    if flag == 'monthheader' and not styles.monthheader then
        flag = 'header'
    end

    -- highlight only today's day
    if flag == 'focus' then
        local today = os.date('*t')
        if today.month ~= date.month then
            flag = 'normal'
        end
    end

    local props = styles[flag] or {}
    if props.markup and widget.get_text and widget.set_markup then
        widget:set_markup(props.markup(widget:get_text()))
    end
    -- Change bg color for weekends
    local d = { year = date.year, month = (date.month or 1), day = (date.day or 1) }
    local weekday = tonumber(os.date('%w', os.time(d)))
    local default_bg = (weekday == 0 or weekday == 6) and '#3B4252' or '#2E3440'
    local ret = wibox.widget {
        {
            {
                widget,
                halign = 'center',
                widget = wibox.container.place
            },
            margins = (props.padding or 2) + (props.border_width or 0),
            widget = wibox.container.margin
        },
        shape = props.shape,
        shape_border_color = props.border_color or '#b9214f',
        shape_border_width = props.border_width or 0,
        fg = props.fg_color or '#D8DEE9',
        bg = props.bg_color or default_bg,
        widget = wibox.container.background
    }

    return ret
end

local cal = wibox.widget {
    date = os.date('*t'),
    font = beautiful.get_font(),
    fn_embed = decorate_cell,
    long_weekdays = true,
    widget = wibox.widget.calendar.month
}

local popup = awful.popup {
    ontop = true,
    visible = false,
    shape = gears.shape.rounded_rect,
    preferred_positions = top,
    offset = { y = 5 },
    border_width = 1,
    border_color = '#4C566A',
    widget = cal
}

popup:buttons(
        awful.util.table.join(
                awful.button({}, 4, function()
                    local a = cal:get_date()
                    a.month = a.month + 1
                    cal:set_date(nil)
                    cal:set_date(a)
                    popup:set_widget(cal)
                end),
                awful.button({}, 5, function()
                    local a = cal:get_date()
                    a.month = a.month - 1
                    cal:set_date(nil)
                    cal:set_date(a)
                    popup:set_widget(cal)
                end)
        )
)

function calendar_widget.toggle()

    if popup.visible then
        -- to faster render the calendar refresh it and just hide
        cal:set_date(nil) -- the new date is not set without removing the old one
        cal:set_date(os.date('*t'))
        popup:set_widget(nil) -- just in case
        popup:set_widget(cal)
        popup.visible = not popup.visible
    else
        if not beautiful.calendar_placement then
            awful.placement.top(popup, { margins = { top = 30 }, parent = awful.screen.focused() })
        elseif beautiful.calendar_placement == 'top' then
            awful.placement.top(popup, { margins = { top = 30 }, parent = awful.screen.focused() })
        elseif beautiful.calendar_placement == 'top_right' then
            awful.placement.top_right(popup, { margins = { top = 30, right = 10}, parent = awful.screen.focused() })
        elseif beautiful.calendar_placement == 'bottom_right' then
            awful.placement.bottom_right(popup, { margins = { bottom = 20, right = 10}, parent = awful.screen.focused() })
        else
            awful.placement.top(popup, { margins = { top = 30 }, parent = awful.screen.focused() })
        end

        popup.visible = true

    end
end

return calendar_widget
