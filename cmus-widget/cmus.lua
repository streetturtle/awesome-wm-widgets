-------------------------------------------------
-- Cmus Widget for Awesome Window Manager
-- Show what's playing, play/pause, etc

-- @author Augusto Gunsch
-- @copyright 2022 Augusto Gunsch
-------------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local watch = require("awful.widget.watch")
local spawn = require("awful.spawn")
local naughty = require("naughty")

local cmus_widget = {}

local function show_warning(message)
    naughty.notify{
        preset = naughty.config.presets.critical,
        title = "Cmus Widget",
        text = message}
end

local function worker(user_args)

    local args = user_args or {}
    local font = args.font or "Play 9"

    local path_to_icons = args.path_to_icons or "/usr/share/icons/Arc/actions/symbolic/"
    local timeout = args.timeout or 10
    local space = args.space or 3

    cmus_widget.widget = wibox.widget {
        {
            {
                id = "playback_icon",
                resize = false,
                widget = wibox.widget.imagebox,
            },
            layout = wibox.container.place
        },
        {
            id = "text",
            font = font,
            widget = wibox.widget.textbox
        },
        layout = wibox.layout.fixed.horizontal,
        update_icon = function(self, name)
            self:get_children_by_id("playback_icon")[1]:set_image(path_to_icons .. name)
        end,
        set_title = function(self, title)
            self:get_children_by_id("text")[1]:set_text(title)
        end
    }

    function update_widget(widget, stdout, _, _, code)
        if code == 0 then
            local cmus_info = {}

            for s in stdout:gmatch("[^\r\n]+") do
                local key, val = string.match(s, "^tag (%a+) (.+)$")

                if key and val then
                    cmus_info[key] = val
                else
                    local key, val = string.match(s, "^set (%a+) (.+)$")

                    if key and val then
                        cmus_info[key] = val
                    else
                        local key, val = string.match(s, "^(%a+) (.+)$")
                        if key and val then
                            cmus_info[key] = val
                        end
                    end
                end
            end

            local title = cmus_info.title

            if not title and cmus_info.file then
                title = cmus_info.file:gsub("%..-$", "")
                title = title:gsub("^.+/", "")
            end

            if title then
                if cmus_info["status"] == "playing" then
                    widget:update_icon("media-playback-start-symbolic.svg")
                elseif cmus_info["status"] == "paused" then
                    widget:update_icon("media-playback-pause-symbolic.svg")
                else
                    widget:update_icon("media-playback-stop-symbolic.svg")
                end

                widget:set_title(title)
                widget.visible = true
            else
                widget.visible = false
                widget.width = 0
            end
        else
            widget.visible = false
        end
    end

    function cmus_widget:play_pause()
        spawn("cmus-remote -u")
        spawn.easy_async("cmus-remote -Q",
        function(stdout, _, _, code)
            update_widget(cmus_widget.widget, stdout, _, _, code)
        end)
    end

    cmus_widget.widget:buttons(
            awful.util.table.join(
                    awful.button({}, 1, function() cmus_widget:play_pause() end)
            )
    )

    watch("cmus-remote -Q", timeout, update_widget, cmus_widget.widget)

    return cmus_widget.widget
end

return setmetatable(cmus_widget, { __call = function(_, ...)
    return worker(...)
end })
