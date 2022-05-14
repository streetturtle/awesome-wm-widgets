-------------------------------------------------
-- The Ultimate Volume Widget for Awesome Window Manager
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/volume-widget

-- @author Pavel Makhov
-- @copyright 2020 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local spawn = require("awful.spawn")
local gears = require("gears")
local beautiful = require("beautiful")
local watch = require("awful.widget.watch")
local utils = require("awesome-wm-widgets.volume-widget.utils")


--local LIST_DEVICES_CMD = [[sh -c "pactl list short sinks; pactl list short sources"]]
local LIST_SINKS_CMD = "pactl list short sinks"
local LIST_SOURCES_CMD = "pactl list short sources"
local GET_DEFAULT_SINK_CMD = "pactl get-default-sink"
local GET_DEFAULT_SOURCE_CMD = "pactl get-default-source"
local TOG_VOLUME_CMD = 'pactl set-sink-mute 0 toggle'
--local function GET_VOLUME_CMD(device) return 'amixer -D ' .. device .. ' sget Master' end
local GET_VOLUME_CMD = 'pactl get-sink-volume 0'
local GET_MUTE_CMD =  'pactl get-sink-mute 0'
local function INC_VOLUME_CMD(step) return 'pactl set-sink-volume 0 +' .. step .. '%' end
local function DEC_VOLUME_CMD(step) return 'pactl set-sink-volume 0 -' .. step .. '%' end


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
            --spawn.easy_async(string.format([[sh -c 'pacmd set-default-%s "%s"']], device_type, device.name), function()
            spawn.easy_async(string.format([[sh -c 'pactl set-default-%s "%s"']], device_type, device.name), function()
                on_checkbox_click()
            end)
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
                            --text = build_main_line(device),
                            text = device.name,
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
            --spawn.easy_async(string.format([[sh -c 'pacmd set-default-%s "%s"']], device_type, device.name), function()
            spawn.easy_async(string.format([[sh -c 'pactl set-default-%s "%s"']], device_type, device.name), function()
                on_checkbox_click()
            end)
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
    --spawn.easy_async(LIST_DEVICES_CMD, function(stdout)

    --    local sinks, sources = utils.extract_sinks_and_sources(stdout)

    --    for i = 0, #rows do rows[i]=nil end

    --    table.insert(rows, build_header_row("SINKS"))
    --    table.insert(rows, build_rows(sinks, function() rebuild_popup() end, "sink"))
    --    table.insert(rows, build_header_row("SOURCES"))
    --    table.insert(rows, build_rows(sources, function() rebuild_popup() end, "source"))

    --    popup:setup(rows)
    --end)
    local count = 0
    local sinks
    local sources
    local default_sink
    local default_source
    local function try_setup()
        count = count + 1
        if count == 4 then
            for _, sink in pairs(sinks) do
                sink.is_default = sink.name == default_sink
            end
            for _, source in pairs(sources) do
                source.is_default = source.name == default_source
            end
            for i = 0, #rows do rows[i]=nil end
            table.insert(rows, build_header_row("SINKS"))
            table.insert(rows, build_rows(sinks, function() rebuild_popup() end, "sink"))
            table.insert(rows, build_header_row("SOURCES"))
            table.insert(rows, build_rows(sources, function() rebuild_popup() end, "source"))
            popup:setup(rows)
        end
    end
    spawn.easy_async(LIST_SINKS_CMD, function(stdout)
        sinks = utils.extract_pactl_devices(stdout)
        try_setup()
    end)
    spawn.easy_async(LIST_SOURCES_CMD, function(stdout)
        sources = utils.extract_pactl_devices(stdout)
        try_setup()
    end)
    spawn.easy_async(GET_DEFAULT_SINK_CMD, function(stdout)
        default_sink = utils.trim(stdout)
        try_setup()
    end)
    spawn.easy_async(GET_DEFAULT_SOURCE_CMD, function(stdout)
        default_source = utils.trim(stdout)
        try_setup()
    end)
end


local function worker(user_args)

    local args = user_args or {}

    local mixer_cmd = args.mixer_cmd or 'pavucontrol'
    local widget_type = args.widget_type
    local refresh_rate = args.refresh_rate or 1
    local step = args.step or 5

    if widget_types[widget_type] == nil then
        volume.widget = widget_types['icon_and_text'].get_widget(args.icon_and_text_args)
    else
        volume.widget = widget_types[widget_type].get_widget(args)
    end

    function volume:inc(s)
        spawn.spawn(INC_VOLUME_CMD(s or step))
    end

    function volume:dec(s)
        spawn.spawn(DEC_VOLUME_CMD(s or step))
    end

    function volume:toggle()
        spawn.spawn(TOG_VOLUME_CMD)
    end

    function volume:mixer()
        if mixer_cmd then
            spawn.spawn(TOG_VOLUME_CMD)
        end
    end

    volume.widget:buttons(
            awful.util.table.join(
                    awful.button({}, 3, function()
                        if popup.visible then
                            popup.visible = not popup.visible
                        else
                            rebuild_popup()
                            popup:move_next_to(mouse.current_widget_geometry)
                        end
                    end),
                    awful.button({}, 4, function() volume:inc() end),
                    awful.button({}, 5, function() volume:dec() end),
                    awful.button({}, 2, function() volume:mixer() end),
                    awful.button({}, 1, function() volume:toggle() end)
            )
    )

    local mute
    local volume_level
    watch(GET_MUTE_CMD, refresh_rate, function (widget, stdout)
        mute = string.match(stdout, "Mute: (%D%D%D?)")   -- Mute: yes/no
        if mute == 'yes' then widget:mute()
        elseif mute == 'no' then widget:unmute()
        end
        if volume_level ~= nil then
            widget:set_volume_level(volume_level)
        end
    end, volume.widget)
    watch(GET_VOLUME_CMD, refresh_rate, function (widget, stdout)
        local v = string.match(stdout, "(%d?%d?%d)%%") -- (\d?\d?\d)\%)
        if v ~= nil then
            volume_level = string.format("% 3d", v)
            widget:set_volume_level(volume_level)
        end
    end, volume.widget)

    return volume.widget
end

return setmetatable(volume, { __call = function(_, ...) return worker(...) end })
