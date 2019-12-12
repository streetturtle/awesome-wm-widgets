-------------------------------------------------
-- Calendar Widget for Awesome Window Manager
-- Shows the current month and supports scroll up/down to switch month
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/calendar-widget

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
local gs = require("gears.string")

local calendar_widget = {}

local styles = {}
local function rounded_shape(size, partial)
    if partial then
        return function(cr, width, height)
            gears.shape.partially_rounded_rect(cr, width, height,
                    false, true, false, true, 5)
        end
    else
        return function(cr, width, height)
            gears.shape.rounded_rect(cr, width, height, size)
        end
    end
end
styles.month   = { padding      = 4,
                   bg_color     = '#3B4252',
                   border_width = 0,
}
styles.normal  = {
    markup   = function(t) return t end,
    shape    = rounded_shape(4)
}
styles.focus   = { fg_color = '#000000',
                   bg_color = '#88C0D0',
                   markup   = function(t) return '<b>' .. t .. '</b>' end,
                   shape    = rounded_shape(4)
}
styles.header  = { fg_color = '#8FBCBB',
                   markup   = function(t) return '<b>' .. t .. '</b>' end,
                   --shape    = rounded_shape(10)
                   bg_color = '#3B4252'
}
styles.weekday = { fg_color = '#88C0D0',
                   markup   = function(t) return '<b>' .. t .. '</b>' end,
                   bg_color = '#3B4252',
                   --shape    = rounded_shape(4)
}

local function decorate_cell(widget, flag, date)
    if flag=='monthheader' and not styles.monthheader then
        flag = 'header'
    end

    if flag == 'focus' then
        local a = os.date('*t')
        if a.month ~= date.month then
            flag = 'normal'
        end
    end

    local props = styles[flag] or {}
    if props.markup and widget.get_text and widget.set_markup then
        widget:set_markup(props.markup(widget:get_text()))
    end
    -- Change bg color for weekends
    local d = {year=date.year, month=(date.month or 1), day=(date.day or 1)}
    local weekday = tonumber(os.date('%w', os.time(d)))
    local default_bg = (weekday==0 or weekday==6) and '#2E3440' or '#3B4252'
    local ret = wibox.widget {
        {
            {
                widget,
                halign = 'center',
                widget = wibox.container.place
            },
            margins = (props.padding or 2) + (props.border_width or 0),
            widget  = wibox.container.margin
        },
        shape              = props.shape,
        shape_border_color = props.border_color or '#b9214f',
        shape_border_width = props.border_width or 0,
        fg                 = props.fg_color or '#D8DEE9',
        bg                 = props.bg_color or default_bg,
        widget             = wibox.container.background
    }

--         ret:connect_signal("mouse::enter", function(c) naughty.notify{text = 'asd ' .. flag} end)

    return ret
end

local cal = wibox.widget {
    date     = os.date('*t'),
    font = 'Play 9',
    fn_embed = decorate_cell,
    long_weekdays = true,
    widget   = wibox.widget.calendar.month
}

local popup = awful.popup{
    ontop = true,
    visible = false,
    shape = gears.shape.rounded_rect,
    preferred_positions = top,
    offset = { y = 5 },
    widget = {}
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

calendar_widget = wibox.widget.textbox()
calendar_widget:set_text('calendar')

function calendar_widget.toggle()
    if popup.visible then
        cal:set_date(nil)
        popup.visible = not popup.visible
    else
        cal:set_date(nil)
        cal:set_date(os.date('*t'))
        popup:set_widget(cal)
        popup:move_next_to(mouse.current_widget_geometry)
    end
end

local function toggle()
    calendar_widget.toggle()
end

calendar_widget:buttons(
        awful.util.table.join(
                awful.button({}, 1, function()
                    toggle()
                end)
        )
)

return calendar_widget
