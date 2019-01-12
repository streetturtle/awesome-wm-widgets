-------------------------------------------------
-- Spotify Shell for Awesome Window Manager
-- Simplifies interaction with Spotify for Linux
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/spotify-shell

-- @author Pavel Makhov
-- @copyright 2018 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local gfs = require("gears.filesystem")
local wibox = require("wibox")
local gears = require("gears")
local completion = require("awful.completion")

local run_shell = awful.widget.prompt()

local w = wibox {
    bg = '#2e3440',
    border_width = 1,
    border_color = '#3b4252',
    max_widget_size = 500,
    ontop = true,
    height = 50,
    width = 250,
    shape = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, 3)
--     `   gears.shape.infobubble(cr, width, height)
    end
}

w:setup {
    {
        {
            markup = '<span font="awesomewm-font 14" color="#ffffff">a</span>',
            widget = wibox.widget.textbox,
        },
        id = 'icon',
        top = 2,
        left = 10,
        layout = wibox.container.margin
    },
    {
        layout = wibox.container.margin,
        left = 10,
        run_shell,
    },
    id = 'left',
    layout = wibox.layout.fixed.horizontal
}

local function launch()
    w.visible = true

    awful.placement.top(w, { margins = {top = 40}, parent = awful.screen.focused()})
    awful.prompt.run {
        prompt = 'Run: ',
        bg_cursor = '#74aeab',
        textbox = run_shell.widget,
        completion_callback = completion.shell,
        exe_callback = function(...)
            run_shell:spawn_and_handle_error(...)
        end,
        history_path = gfs.get_cache_dir() .. "/history",
        done_callback = function()
            w.visible = false
        end
    }
end

return {
    launch = launch
}
