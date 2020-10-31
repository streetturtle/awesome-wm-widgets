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
local utils = require("awesome-wm-widgets.experiments.volume.utils")


local HOME_DIR = os.getenv("HOME")
local WIDGET_DIR = HOME_DIR .. '/.config/awesome/awesome-wm-widgets/experiments/volume'
local LIST_DEVICES_CMD = [[sh -c "pacmd list-sinks; pacmd list-sources"]]


local rows  = { layout = wibox.layout.fixed.vertical }
local volume_widget = wibox.widget {
    {
        {
            id = "icon",
            image = WIDGET_DIR .. '/volume-2.svg',
            widget = wibox.widget.imagebox
        },
        id = "margin",
        margins = 4,
        layout = wibox.container.margin
    },
    {
        id = "txt",
        widget = wibox.widget.textbox
    },
    layout = wibox.layout.fixed.horizontal,
    set_text = function(self, new_value)
        self.txt.text = new_value
    end,
    set_icon = function(self, new_value)
        self.margin.icon.image = new_value
    end
}


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
        return device.properties.device_description .. ' - ' .. device.ports[device.active_port]
    else
        return device.properties.device_description
    end
end

local function build_rows(devices, on_checkbox_click, device_type)
    local device_rows  = { layout = wibox.layout.fixed.vertical }
    for _, device in pairs(devices) do

        local checkbox = wibox.widget {
            checked       = device.is_default,
            color         = beautiful.bg_normal,
            paddings      = 2,
            shape         = gears.shape.circle,
            forced_width = 20,
            forced_height = 20,
            check_color = beautiful.fg_urgent,
            widget        = wibox.widget.checkbox
        }

        checkbox:connect_signal("button::press", function(c)
            print(string.format([[sh -c 'pacmd set-default-%s "%s"']], device_type, device.name))
            spawn.easy_async(string.format([[sh -c 'pacmd set-default-%s "%s"']], device_type, device.name), function()
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
                margins = 8,
                layout = wibox.container.margin
            },
            bg = beautiful.bg_normal,
            widget = wibox.container.background
        }

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
    spawn.easy_async(LIST_DEVICES_CMD, function(stdout)

        local sinks, sources = utils.extract_sinks_and_sources(stdout)

        for i = 0, #rows do rows[i]=nil end

        table.insert(rows, build_header_row("SINKS"))
        table.insert(rows, build_rows(sinks, function() rebuild_popup() end, "sink"))
        table.insert(rows, build_header_row("SOURCES"))
        table.insert(rows, build_rows(sources, function() rebuild_popup() end, "source"))

        popup:setup(rows)
    end)

end


local function worker(args)

    volume_widget:buttons(
            awful.util.table.join(
                    awful.button({}, 1, function()
                        if popup.visible then
                            popup.visible = not popup.visible
                        else
                            rebuild_popup()
                            popup:move_next_to(mouse.current_widget_geometry)
                        end
                    end)
            )
    )

    return volume_widget
end

return setmetatable(volume_widget, { __call = function(_, ...) return worker(...) end })
