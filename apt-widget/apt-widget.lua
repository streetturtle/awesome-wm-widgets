-------------------------------------------------
-- APT Widget for Awesome Window Manager
-- Lists containers and allows to manage them
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/apt-widget

-- @author Pavel Makhov
-- @copyright 2021 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local spawn = require("awful.spawn")
local naughty = require("naughty")
local gears = require("gears")
local beautiful = require("beautiful")

local HOME_DIR = os.getenv("HOME")
local WIDGET_DIR = HOME_DIR .. '/.config/awesome/awesome-wm-widgets/apt-widget'
local ICONS_DIR = WIDGET_DIR .. '/icons/'

local LIST_PACKAGES = [[sh -c "apt list --upgradable 2>/dev/null"]]

--- Utility function to show warning messages
local function show_warning(message)
    naughty.notify{
        preset = naughty.config.presets.critical,
        title = 'Docker Widget',
        text = message}
end

local wibox_popup = wibox {
    ontop = true,
    visible = false,
    shape = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, 4)
    end,
    border_width = 1,
    border_color = beautiful.bg_focus,
    max_widget_size = 500,
    height = 500,
    width = 300,
}

local apt_widget = wibox.widget {
    {
        {
            id = 'icon',
            widget = wibox.widget.imagebox
        },
        margins = 4,
        layout = wibox.container.margin
    },
    layout = wibox.layout.fixed.horizontal,
    set_icon = function(self, new_icon)
        self:get_children_by_id("icon")[1].image = new_icon
    end
}

--- Parses the line and creates the package table out of it
--- yaru-theme-sound/focal-updates,focal-updates 20.04.10.1 all [upgradable from: 20.04.8]
local parse_package = function(line)
    local name,_,nv,type,ov = line:match('(.*)%/(.*)%s(.*)%s(.*)%s%[upgradable from: (.*)]')

    if name == nil then return nil end

    local package = {
        name = name,
        new_version = nv,
        type = type,
        old_version = ov
    }
    return package
end

local function worker(user_args)

    local args = user_args or {}

    local icon = args.icon or ICONS_DIR .. 'white-black.svg'

    apt_widget:set_icon(icon)

    local pointer = 0
    local min_widgets = 5
    local carousel = false

    local function rebuild_widget(containers, errors, _, _)

        local to_update = {}

        if errors ~= '' then
            show_warning(errors)
            return
        end

        local rows = wibox.layout.fixed.vertical()
        rows:connect_signal("button::press", function(_,_,_,button)
            if carousel then
                if button == 4 then -- up scrolling
                    local cnt = #rows.children
                    local first_widget = rows.children[1]
                    rows:insert(cnt+1, first_widget)
                    rows:remove(1)
                elseif button == 5 then -- down scrolling
                    local cnt = #rows.children
                    local last_widget = rows.children[cnt]
                    rows:insert(1, last_widget)
                    rows:remove(cnt+1)
                end
            else
                if button == 5 then -- up scrolling
                    if pointer < #rows.children and ((#rows.children - pointer) >= min_widgets) then
                        pointer = pointer + 1
                        rows.children[pointer].visible = false
                    end
                elseif button == 4 then -- down scrolling
                    if pointer > 0 then
                        rows.children[pointer].visible = true
                        pointer = pointer - 1
                    end
                end
            end
        end)

        for line in containers:gmatch("[^\r\n]+") do
            local package = parse_package(line)

            if package ~= nil then

                local refresh_button = wibox.widget {
                    {
                        {
                            id = 'icon',
                            image = ICONS_DIR .. 'refresh-cw.svg',
                            resize = false,
                            widget = wibox.widget.imagebox
                        },
                        margins = 4,
                        widget = wibox.container.margin
                    },
                    shape = gears.shape.circle,
                    opacity = 0.5,
                    widget = wibox.container.background
                }
                local old_cursor, old_wibox
                refresh_button:connect_signal("mouse::enter", function(c)
                    c:set_opacity(1)
                    c:emit_signal('widget::redraw_needed')
                    local wb = mouse.current_wibox
                    old_cursor, old_wibox = wb.cursor, wb
                    wb.cursor = "hand1"
                end)
                refresh_button:connect_signal("mouse::leave", function(c)
                    c:set_opacity(0.5)
                    c:emit_signal('widget::redraw_needed')
                    if old_wibox then
                        old_wibox.cursor = old_cursor
                        old_wibox = nil
                    end
                end)

                local row = wibox.widget {
                    {
                        {
                            {
                                {
                                    id = 'checkbox',
                                    checked       = false,
                                    color         = beautiful.bg_normal,
                                    paddings      = 2,
                                    shape         = gears.shape.circle,
                                    forced_width = 20,
                                    forced_height = 20,
                                    check_color = beautiful.fg_urgent,
                                    border_color = beautiful.bg_urgent,
                                    border_width = 1,
                                    widget        = wibox.widget.checkbox
                                },
                                valign = 'center',
                                layout = wibox.container.place,
                            },
                            {
                                {
                                    id = 'name',
                                    markup = '<b>' .. package['name'] .. '</b>',
                                    widget = wibox.widget.textbox
                                },
                                halign = 'left',
                                layout = wibox.container.place
                            },
                            {
                                refresh_button,
                                halign = 'right',
                                valigh = 'center',
                                fill_horizontal = true,
                                layout = wibox.container.place,
                            },
                            spacing = 8,
                            layout = wibox.layout.fixed.horizontal
                        },
                        margins = 8,
                        layout = wibox.container.margin
                    },
                    id = 'row',
                    bg = beautiful.bg_normal,
                    widget = wibox.container.background,
                    click = function(self, checked)
                        local a = self:get_children_by_id('checkbox')[1]
                        if checked == nil then
                            a:set_checked(not a.checked)
                        else
                            a:set_checked(checked)
                        end

                        if a.checked then
                            to_update[package['name']] = self
                        else
                            to_update[package['name']] = false
                        end
                    end,
                    update = function(self)
                        refresh_button:get_children_by_id('icon')[1]:set_image(ICONS_DIR .. 'watch.svg')
                        self:get_children_by_id('name')[1]:set_opacity(0.4)
                        self:get_children_by_id('name')[1]:emit_signal('widget::redraw_needed')

                        spawn.easy_async(
                            string.format([[sh -c 'yes | aptdcon --hide-terminal -u %s']], package['name']),
                            function(stdout, stderr) -- luacheck:ignore 212
                                rows:remove_widgets(self)
                        end)

                    end
                }

                row:connect_signal("mouse::enter", function(c)
                    c:set_bg(beautiful.bg_focus)
                end)
                row:connect_signal("mouse::leave", function(c)
                    c:set_bg(beautiful.bg_normal)
                end)

                row:connect_signal("button::press", function(c, _, _, button)
                    if button == 1 then c:click() end
                end)

                refresh_button:buttons(awful.util.table.join(awful.button({}, 1, function()
                    row:update()
                end)))

                rows:add(row)
            end
        end


        local header_checkbox = wibox.widget {
            checked       = false,
            color         = beautiful.bg_normal,
            paddings      = 2,
            shape         = gears.shape.circle,
            forced_width = 20,
            forced_height = 20,
            check_color = beautiful.fg_urgent,
            border_color = beautiful.bg_urgent,
            border_width = 1,
            widget        = wibox.widget.checkbox
        }
        header_checkbox:connect_signal("button::press", function(c)
            c:set_checked(not c.checked)
            local cbs = rows.children
            for _,v in ipairs(cbs) do
                v:click(c.checked)
            end
        end)

        local header_refresh_icon = wibox.widget {
            image = ICONS_DIR .. 'refresh-cw.svg',
            resize = false,
            widget = wibox.widget.imagebox
        }
        header_refresh_icon:buttons(awful.util.table.join(awful.button({}, 1, function()
            print(#to_update)
            for _,v in pairs(to_update) do
                if v ~= nil then
                    v:update()
                end
            end
        end)))

        local header_row = wibox.widget {
            {
                {
                    {
                        header_checkbox,
                        valign = 'center',
                        layout = wibox.container.place,
                    },
                    {
                        {
                            id = 'name',
                            markup = '<b>' .. #rows.children .. '</b> packages to update',
                            widget = wibox.widget.textbox
                        },
                        halign = 'center',
                        layout = wibox.container.place
                    },
                    {
                        header_refresh_icon,
                        halign = 'right',
                        valigh = 'center',
                        layout = wibox.container.place,
                    },
                    layout = wibox.layout.align.horizontal
                },
                margins = 8,
                layout = wibox.container.margin
            },
            bg = beautiful.bg_normal,
            widget = wibox.container.background
        }

        wibox_popup:setup {
            header_row,
            rows,
            layout = wibox.layout.fixed.vertical
        }
    end

    apt_widget:buttons(
            awful.util.table.join(
                    awful.button({}, 1, function()
                        if wibox_popup.visible then
                            wibox_popup.visible = not wibox_popup.visible
                        else
                            spawn.easy_async(LIST_PACKAGES,
                                    function(stdout, stderr)
                                        rebuild_widget(stdout, stderr)
                                        wibox_popup.visible = true
                                        awful.placement.top(wibox_popup, { margins = { top = 20 }, parent = mouse})
                                    end)
                        end
                    end)
            )
    )

    return apt_widget
end

return setmetatable(apt_widget, { __call = function(_, ...) return worker(...) end })
