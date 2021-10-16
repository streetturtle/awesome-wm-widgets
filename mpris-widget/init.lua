-------------------------------------------------
-- mpris based Arc Widget for Awesome Window Manager
-- Modelled after Pavel Makhov's work
-- @author Mohammed Gaber
-- requires - playerctl
-- @copyright 2020
-------------------------------------------------
local awful = require("awful")
local beautiful = require("beautiful")
local watch = require("awful.widget.watch")
local wibox = require("wibox")
local gears = require("gears")

local GET_MPD_CMD = "playerctl -p %s -f '{{status}};{{xesam:artist}};{{xesam:title}}' metadata"

local TOGGLE_MPD_CMD = "playerctl play-pause"
local NEXT_MPD_CMD = "playerctl next"
local PREV_MPD_CMD = "playerctl previous"
local LIST_PLAYERS_CMD = "playerctl -l"

local PATH_TO_ICONS = "/usr/share/icons/Arc"
local PAUSE_ICON_NAME = PATH_TO_ICONS .. "/actions/24/player_pause.png"
local PLAY_ICON_NAME = PATH_TO_ICONS .. "/actions/24/player_play.png"
local STOP_ICON_NAME = PATH_TO_ICONS .. "/actions/24/player_stop.png"
local LIBRARY_ICON_NAME = PATH_TO_ICONS .. "/actions/24/music-library.png"

local default_player = ''

local icon = wibox.widget {
    id = "icon",
    widget = wibox.widget.imagebox,
    image = PLAY_ICON_NAME
}

local mpris_widget = wibox.widget{
    {
        id = 'artist',
        widget = wibox.widget.textbox
    },
    {
        icon,
        max_value = 1,
        value = 0,
        thickness = 2,
        start_angle = 4.71238898, -- 2pi*3/4
        forced_height = 24,
        forced_width = 24,
        rounded_edge = true,
        bg = "#ffffff11",
        paddings = 0,
        widget = wibox.container.arcchart
    },
    {
        id = 'title',
        widget = wibox.widget.textbox
    },
    layout = wibox.layout.fixed.horizontal,
    set_text = function(self, artist, title)
        self:get_children_by_id('artist')[1]:set_text(artist)
        self:get_children_by_id('title')[1]:set_text(title)
    end
}

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

local function rebuild_popup()
    awful.spawn.easy_async(LIST_PLAYERS_CMD, function(stdout, _, _, _)
        for i = 0, #rows do rows[i]=nil end
        for player_name in stdout:gmatch("[^\r\n]+") do
            if player_name ~='' and player_name ~=nil then

                local checkbox = wibox.widget{
                    {
                        checked       = player_name == default_player,
                        color         = beautiful.bg_normal,
                        paddings      = 2,
                        shape         = gears.shape.circle,
                        forced_width = 20,
                        forced_height = 20,
                        check_color = beautiful.fg_urgent,
                        widget        = wibox.widget.checkbox
                    },
                    valign = 'center',
                    layout = wibox.container.place,
                }

                checkbox:connect_signal("button::press", function()
                    default_player = player_name
                    rebuild_popup()
                end)

                table.insert(rows, wibox.widget {
                    {
                        {
                            checkbox,
                            {
                                {
                                    text = player_name,
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
                })
            end
        end
    end)

    popup:setup(rows)
end

local function worker()

    -- retrieve song info
    local current_song, artist, player_status

    local update_graphic = function(widget, stdout, _, _, _)
        local words = gears.string.split(stdout, ';')
        player_status = words[1]
        artist = words[2]
        current_song = words[3]
        if current_song ~= nil then
            if string.len(current_song) > 18 then
                current_song = string.sub(current_song, 0, 9) .. ".."
            end
        end

        if player_status == "Playing" then
            icon.image = PLAY_ICON_NAME
            widget.colors = {beautiful.widget_main_color}
            widget:set_text(artist, current_song)
        elseif player_status == "Paused" then
            icon.image = PAUSE_ICON_NAME
            widget.colors = {beautiful.widget_main_color}
            widget:set_text(artist, current_song)
        elseif player_status == "Stopped" then
            icon.image = STOP_ICON_NAME
        else -- no player is running
            icon.image = LIBRARY_ICON_NAME
            widget.colors = {beautiful.widget_red}
        end
    end

    mpris_widget:buttons(
            awful.util.table.join(
                    awful.button({}, 3, function()
                        if popup.visible then
                            popup.visible = not popup.visible
                        else
                            rebuild_popup()
                            popup:move_next_to(mouse.current_widget_geometry)
                        end
                    end),
                    awful.button({}, 4, function() awful.spawn(NEXT_MPD_CMD, false) end),
                    awful.button({}, 5, function() awful.spawn(PREV_MPD_CMD, false) end),
                    awful.button({}, 1, function() awful.spawn(TOGGLE_MPD_CMD, false) end)
            )
    )

    watch(string.format(GET_MPD_CMD, "'" .. default_player .. "'"), 1, update_graphic, mpris_widget)

    return mpris_widget

end

return setmetatable(mpris_widget, {__call = function(_, ...) return worker(...) end})
