-------------------------------------------------
-- A purely pactl-based volume widget based on the original Volume widget
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/pactl-widget

-- @author Stefan Huber
-- @copyright 2023 Stefan Huber
-------------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local spawn = require("awful.spawn")
local gears = require("gears")
local beautiful = require("beautiful")

local pactl = require("awesome-wm-widgets.pactl-widget.pactl")
local utils = require("awesome-wm-widgets.pactl-widget.utils")


local widget_types = {
    icon_and_text = require("awesome-wm-widgets.volume-widget.widgets.icon-and-text-widget"),
    icon = require("awesome-wm-widgets.volume-widget.widgets.icon-widget"),
    arc = require("awesome-wm-widgets.volume-widget.widgets.arc-widget"),
    horizontal_bar = require("awesome-wm-widgets.volume-widget.widgets.horizontal-bar-widget"),
    vertical_bar = require("awesome-wm-widgets.volume-widget.widgets.vertical-bar-widget")
}
local volume = {}

local rows  = { layout = wibox.layout.fixed.vertical }

local popup = awful.popup{
    bg = beautiful.bg_normal,
    ontop = true,
    visible = false,
    shape = gears.shape.rounded_rect,
    border_width = 1,
    border_color = beautiful.bg_focus,
    maximum_width = 400,
    offset = { y = 5 },
    widget = {}
}

local function build_main_line(device)
    if device.active_port ~= nil and device.ports[device.active_port] ~= nil then
        return device.description .. ' · ' .. utils.split(device.ports[device.active_port], " ")[1]
    else
        return device.description
    end
end

local function build_rows(devices, on_checkbox_click, device_type)
    local device_rows  = { layout = wibox.layout.fixed.vertical }
    for _, device in pairs(devices) do

        local checkbox = wibox.widget {
            checked = device.is_default,
            color = beautiful.bg_normal,
            paddings = 2,
            shape = gears.shape.circle,
            forced_width = 20,
            forced_height = 20,
            check_color = beautiful.fg_urgent,
            widget = wibox.widget.checkbox
        }

        checkbox:connect_signal("button::press", function()
            pactl.set_default(device_type, device.name)
            on_checkbox_click()
        end)

        local row = wibox.widget {
            {
                {
                    {
                        checkbox,
                        valign = 'center',
                        layout = wibox.container.place,
                    },
                    {
                        {
                            text = build_main_line(device),
                            align = 'left',
                            widget = wibox.widget.textbox
                        },
                        left = 10,
                        layout = wibox.container.margin
                    },
                    spacing = 8,
                    layout = wibox.layout.align.horizontal
                },
                margins = 4,
                layout = wibox.container.margin
            },
            bg = beautiful.bg_normal,
            widget = wibox.container.background
        }

        row:connect_signal("mouse::enter", function(c) c:set_bg(beautiful.bg_focus) end)
        row:connect_signal("mouse::leave", function(c) c:set_bg(beautiful.bg_normal) end)

        local old_cursor, old_wibox
        row:connect_signal("mouse::enter", function()
            local wb = mouse.current_wibox
            old_cursor, old_wibox = wb.cursor, wb
            wb.cursor = "hand1"
        end)
        row:connect_signal("mouse::leave", function()
            if old_wibox then
                old_wibox.cursor = old_cursor
                old_wibox = nil
            end
        end)

        row:connect_signal("button::press", function()
            pactl.set_default(device_type, device.name)
            on_checkbox_click()
        end)

        table.insert(device_rows, row)
    end

    return device_rows
end

local function build_header_row(text)
    return wibox.widget{
        {
            markup = "<b>" .. text .. "</b>",
            align = 'center',
            widget = wibox.widget.textbox
        },
        bg = beautiful.bg_normal,
        widget = wibox.container.background
    }
end

local function rebuild_popup()
    for i = 0, #rows do
        rows[i]=nil
    end

    local sinks, sources = pactl.get_sinks_and_sources()
    table.insert(rows, build_header_row("SINKS"))
    table.insert(rows, build_rows(sinks, function() rebuild_popup() end, "sink"))
    table.insert(rows, build_header_row("SOURCES"))
    table.insert(rows, build_rows(sources, function() rebuild_popup() end, "source"))

    popup:setup(rows)
end

local function worker(user_args)

    local args = user_args or {}

    local mixer_cmd = args.mixer_cmd or 'pavucontrol'
    local widget_type = args.widget_type
    local refresh_rate = args.refresh_rate or 1
    local step = args.step or 5
    local device = args.device or '@DEFAULT_SINK@'
    local tooltip = args.tooltip or false

    if widget_types[widget_type] == nil then
        volume.widget = widget_types['icon_and_text'].get_widget(args.icon_and_text_args)
    else
        volume.widget = widget_types[widget_type].get_widget(args)
    end

    local function update_graphic(widget)
        local vol = pactl.get_volume(device)
        if vol ~= nil then
            widget:set_volume_level(vol)
        end

        if pactl.get_mute(device) then
            widget:mute()
        else
            widget:unmute()
        end
    end

    function volume:inc(s)
        pactl.volume_increase(device, s or step)
        update_graphic(volume.widget)
    end

    function volume:dec(s)
        pactl.volume_decrease(device, s or step)
        update_graphic(volume.widget)
    end

    function volume:toggle()
        pactl.mute_toggle(device)
        update_graphic(volume.widget)
    end

    function volume:popup()
        if popup.visible then
            popup.visible = not popup.visible
        else
            rebuild_popup()
            popup:move_next_to(mouse.current_widget_geometry)
        end
    end

    function volume:mixer()
        if mixer_cmd then
            spawn(mixer_cmd)
        end
    end

    volume.widget:buttons(
            awful.util.table.join(
                    awful.button({}, 1, function() volume:toggle() end),
                    awful.button({}, 2, function() volume:mixer() end),
                    awful.button({}, 3, function() volume:popup() end),
                    awful.button({}, 4, function() volume:inc() end),
                    awful.button({}, 5, function() volume:dec() end)
            )
    )

    gears.timer {
        timeout   = refresh_rate,
        call_now  = true,
        autostart = true,
        callback  = function()
            update_graphic(volume.widget)
        end
    }

    if tooltip then
        awful.tooltip {
            objects        = { volume.widget },
            timer_function = function()
                return pactl.get_volume(device) .. " %"
            end,
        }
    end

    return volume.widget
end


return setmetatable(volume, { __call = function(_, ...) return worker(...) end })
