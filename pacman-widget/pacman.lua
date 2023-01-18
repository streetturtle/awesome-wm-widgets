local naughty = require("naughty")
local wibox = require("wibox")
local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")

local DIR = os.getenv("HOME") .. "/.config/awesome/pacman-widget/"
local ICON_DIR = DIR .. "icons/"

local pacman_widget = {}
local config, timer = {}, {}

config.interval = 600
config.popup_bg_color = "#222222"
config.popup_border_width = 1
config.popup_border_color = "#7e7e7e"
config.popup_height = 10
config.popup_width = 300
config.polkit_agent_path = "/usr/bin/lxpolkit"

local function worker(user_args)
    local args, _config = user_args or {}, {}
    for prop, value in pairs(config) do
        _config[prop] = args[prop] or beautiful[prop] or value
    end

    awful.spawn.once(_config.polkit_agent_path)

    pacman_widget = wibox.widget {
        {
            {
                id = "icon",
                resize = false,
                widget = wibox.widget.imagebox,
            },
            valign = "center",
            layout = wibox.container.place,
        },
        {
            id = "txt",
            font = args.font,
            widget = wibox.widget.textbox
        },
        spacing = 5,
        layout = wibox.layout.fixed.horizontal,
    }
    function pacman_widget.set(new_value)
        pacman_widget:get_children_by_id("txt")[1]:set_text(new_value)
        pacman_widget:get_children_by_id("icon")[1]:set_image(
            ICON_DIR .. (tonumber(new_value) > 0 and "pacman" or "pacman-full") .. ".svg"
        )
    end

    local rows, ptr = wibox.layout.fixed.vertical(), 0
    rows:connect_signal("button::press", function(_,_,_,button)
          if button == 4 then
              if ptr > 0 then
                  rows.children[ptr].visible = true
                  ptr = ptr - 1
              end
          elseif button == 5 then
              if ptr < #rows.children and ((#rows.children - ptr) > _config.popup_height) then
                  ptr = ptr + 1
                  rows.children[ptr].visible = false
              end
          end
       end)

    local popup = awful.popup {
        border_width = _config.popup_border_width,
        border_color = _config.popup_border_color,
        shape = gears.shape.rounded_rect,
        visible = false,
        ontop = true,
        offset = { y = 5 },
        widget = {}
    }

    pacman_widget:buttons(
        awful.util.table.join(
            awful.button({}, 1, function()
                if popup.visible then
                    popup.visible = false
                else
                    popup.visible = true
                    popup:move_next_to(_G.mouse.current_widget_geometry)
                end
            end)
        )
    )

    local upgr_opacity = 0.6
    local upgr_btn = wibox.widget {
        {
            image = ICON_DIR .. "upgrade.svg",
            resize = false,
            layout = wibox.widget.imagebox
        },
        opacity = upgr_opacity,
        layout = wibox.container.background
    }

    local old_cursor, old_wibox
    local busy, upgrading = false, false
    upgr_btn:connect_signal("mouse::enter", function(c)
        if not busy then
            c:set_opacity(1)
            c:emit_signal("widget::redraw_needed")
            local wb = _G.mouse.current_wibox
            old_cursor, old_wibox = wb.cursor, wb
            wb.cursor = "hand2"
        end
    end)
    upgr_btn:connect_signal("mouse::leave", function(c)
        if not busy then
            c:set_opacity(upgr_opacity)
            c:emit_signal("widget::redraw_needed")
            if old_wibox then
                old_wibox.cursor = old_cursor
                old_wibox = nil
            end
        end
    end)
    upgr_btn:connect_signal("button::press", function(c)
        c:set_opacity(1)
        c:emit_signal("widget::redraw_needed")
        if old_wibox then
            old_wibox.cursor = old_cursor
            old_wibox = nil
        end
        if not busy then
            busy = true
            local one_shot = true
            awful.spawn.with_line_callback("bash -c " .. DIR .. "upgrade", {
                stdout = function()
                    if one_shot then
                        upgrading, one_shot = true, false
                        timer:emit_signal("timeout")
                    end
                end,
                stderr = function(line)
                    if (line ~= nil and line ~= "") then
                        if string.find(line, "warning") then
                            naughty.notify({
                                title = "Warning!",
                                text = line,
                                timeout = 0
                                })
                        else
                            naughty.notify({
                                preset = naughty.config.presets.critical,
                                title = "Error!",
                                text = line,
                            })
                        end
                    end
                end,
                exit = function()
                    upgrading, busy = false, false
                    c:set_opacity(upgr_opacity)
                    c:emit_signal("widget::redraw_needed")
                    timer:emit_signal("timeout")
                end,
            })
        end
    end)

    timer = select(2, awful.widget.watch([[bash -c "checkupdates 2>/dev/null"]],
        _config.interval,
        function(widget, stdout)
            local upgrades_tbl = {}
            for value in stdout:gmatch("([^\n]+)") do
                upgrades_tbl[#upgrades_tbl+1] = value
            end
            widget.set(#upgrades_tbl)

            local popup_header_height, popup_row_height = 30, 20
            local header = wibox.widget {
                {
                    nil,
                    {
                        markup = "<b>" .. (upgrading and "Upgrading " .. #upgrades_tbl .. " Packages" or
                            (#upgrades_tbl == 0 and "No" or #upgrades_tbl) .. " Available Upgrades") .. "</b>",
                        layout = wibox.widget.textbox,
                    },
                    #upgrades_tbl > 0 and {
                        upgr_btn,
                        valign = "center",
                        layout = wibox.container.place,
                    },
                    expand = "none",
                    layout = wibox.layout.align.horizontal,
                },
                forced_height = popup_header_height,
                left = 20,
                right = 20,
                layout = wibox.container.margin
            }

            for k, v in ipairs(upgrades_tbl) do
                for i = 1, #rows.children do
                    if v == rows.children[i].get_txt() then goto continue end
                end
                local row = wibox.widget{
                    {
                        id = "idx",
                        text = tostring(k),
                        widget = wibox.widget.textbox
                    },
                    {
                        id = "txt",
                        text = v,
                        forced_height = popup_row_height,
                        paddings = 1,
                        widget = wibox.widget.textbox
                    },
                    layout = wibox.layout.ratio.horizontal,
                }
                function row.get_txt() return row:get_children_by_id("txt")[1].text end
                function row.set_idx(idx) row:get_children_by_id("idx")[1]:set_text(idx) end
                row:ajust_ratio(2, 0.1, 0.9, 0)
                rows:insert(k, row)
                ::continue::
            end

            local height = popup_header_height + math.min(#upgrades_tbl, _config.popup_height) * popup_row_height
            popup:setup {
                {
                    {
                        {
                            {
                                header,
                                rows,
                                forced_height = height,
                                layout = wibox.layout.fixed.vertical
                            },
                            content_fill_horizontal = true,
                            layout = wibox.container.place
                        },
                        margins = 10,
                        layout = wibox.container.margin
                    },
                    bg = _config.popup_bg_color,
                    layout = wibox.widget.background
                },
                forced_width = _config.popup_width,
                layout = wibox.layout.fixed.horizontal
            }
       end,
       pacman_widget
    ))
    return pacman_widget
end

return setmetatable(pacman_widget, { __call = function(_, ...) return worker(...) end })

