-------------------------------------------------
-- Docker Widget for Awesome Window Manager
-- Lists containers and allows to manage them
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/docker-widget

-- @author Pavel Makhov
-- @copyright 2020 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local watch = require("awful.widget.watch")
local spawn = require("awful.spawn")
local naughty = require("naughty")
local gears = require("gears")
local beautiful = require("beautiful")
local gfs = require("gears.filesystem")

local HOME_DIR = os.getenv("HOME")
local WIDGET_DIR = HOME_DIR .. '/.config/awesome/awesome-wm-widgets/docker-widget'
local ICONS_DIR = WIDGET_DIR .. '/icons/'

--- Utility function to show warning messages
local function show_warning(message)
    naughty.notify{
        preset = naughty.config.presets.critical,
        title = 'Docker Widget',
        text = message}
end

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

local docker_widget = wibox.widget {
    {
        {
            id = 'icon',
            widget = wibox.widget.imagebox
        },
        id = "m",
        margins = 4,
        layout = wibox.container.margin
    },
    {
        id = "txt",
        widget = wibox.widget.textbox
    },
    layout = wibox.layout.fixed.horizontal,
    set_icon = function(self, new_icon)
        self.m.icon.image = new_icon
    end,
    set_text = function(self, new_value)
        self.txt.text = new_value
    end
}

local parse_container = function(line)
    local name, id, image, status, how_long = line:match('(.*)::(.*)::(.*)::(%w*) (.*)')
    local actual_status
    if status == 'Up' and how_long:find('Paused') then actual_status = 'Paused'
    else actual_status = status
    end

    local container = {
        name = name,
        id = id,
        image = image,
        status = actual_status,
        how_long = how_long:gsub('%s?%(.*%)%s?', ''),
        is_up = function() return status == 'Up' end,
        is_paused = function() return how_long:find('Paused') end
    }
    return container
end

local status_to_icon_name = {
    Up = '/usr/share/icons/Arc/actions/16/media-playback-start.png',
    Exited = '/usr/share/icons/Arc/actions/16/media-playback-stop.png',
    Paused = '/usr/share/icons/Arc/actions/16/media-playback-pause.png'
}

local function worker(args)

    local args = args or {}

    local icon = args.icon or ICONS_DIR .. 'docker.svg'

    docker_widget:set_icon(icon)

    local rows = {
        { widget = wibox.widget.textbox },
        layout = wibox.layout.fixed.vertical,
    }

    local function rebuild_widget(stdout, stderr, _, _)
        if stderr ~= '' then
            show_warning(stderr)
            return
        end

        for i = 0, #rows do rows[i]=nil end

        for line in stdout:gmatch("[^\r\n]+") do

            local container = parse_container(line)
            print(container:is_up())
            local name, container_id, image, status, how_long = line:match('(.*)::(.*)::(.*)::(%w*)  (.*)')

            local is_visible
            if status == 'Up' or 'Exited' then is_visible = true else is_visible = false end

            local start_stop_button = wibox.widget {
                image = container:is_up() and '/usr/share/icons/Arc/actions/16/media-playback-stop.png' or '/usr/share/icons/Arc/actions/16/media-playback-start.png',
                visible = is_visible,
                resize = false,
                widget = wibox.widget.imagebox
            }

            local pause_unpause_button = wibox.widget {
                image = container:is_up() and '/usr/share/icons/Arc/actions/16/media-playback-pause.png' or '/usr/share/icons/Arc/actions/16/media-skip-forward.png',
                visible = container.is_up(),
                resize = false,
                widget = wibox.widget.imagebox
            }

            start_stop_button:buttons(
                awful.util.table.join( awful.button({}, 1, function()
                    local command
                    if container:is_up() then command = 'stop' else command = 'start' end

                    awful.spawn.easy_async('docker ' .. command .. ' ' .. container['name'], function(stdout, stderr)
                        if stderr ~= '' then show_warning(stderr) return end
                        spawn.easy_async([[bash -c "docker container ls -a --format '{{.Names}}::{{.ID}}::{{.Image}}::{{.Status}}'"]], function(stdout, stderr)
                            rebuild_widget(stdout, stderr) end)
                        end)
                end) ) )

            pause_unpause_button:buttons(
                awful.util.table.join( awful.button({}, 1, function()
                    local command
                    if container:is_paused() then command = 'unpause' else command = 'pause' end

                    awful.spawn.easy_async('docker ' .. command .. ' ' .. container['name'], function(stdout, stderr)
                        if stderr ~= '' then show_warning(stderr) return end
                        spawn.easy_async([[bash -c "docker container ls -a --format '{{.Names}}::{{.ID}}::{{.Image}}::{{.Status}}'"]], function(stdout, stderr)
                            rebuild_widget(stdout, stderr) end)
                        end)
                end) ) )

            local row = wibox.widget {
                {
                    {
                        {
                            {
                                image = status_to_icon_name[container['status']],
                                resize = false,
                                widget = wibox.widget.imagebox
                            },
                            margins = 8,
                            layout = wibox.container.margin
                        },
                        {
                            {
                                text = container['name'],
                                widget = wibox.widget.textbox
                            },
                            {
                                text = container['how_long'],
                                widget = wibox.widget.textbox
                            },
                            forced_width = 160,
                            layout = wibox.layout.fixed.vertical
                        },
                        {
                            {
                                start_stop_button,
                                pause_unpause_button,
                                layout = wibox.layout.align.horizontal
                            },
                            forced_width = 40,
                            valign = 'center',
                            haligh = 'center',
                            layout = wibox.container.place,
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

            row:connect_signal("mouse::enter", function(c) c:set_bg(beautiful.bg_focus) end)
            row:connect_signal("mouse::leave", function(c) c:set_bg(beautiful.bg_normal) end)

            table.insert(rows, row)
        end

        popup:setup(rows)
    end

    docker_widget:buttons(
        awful.util.table.join(
                awful.button({}, 1, function()
                    if popup.visible then
                        popup.visible = not popup.visible
                    else
                        spawn.easy_async([[bash -c "docker container ls -a --format '{{.Names}}::{{.ID}}::{{.Image}}::{{.Status}}'"]], function(stdout, stderr) rebuild_widget(stdout, stderr) end)
                        popup:move_next_to(mouse.current_widget_geometry)
                    end
                end)
        )
    )

    return docker_widget
end

return setmetatable(docker_widget, { __call = function(_, ...) return worker(...) end })
