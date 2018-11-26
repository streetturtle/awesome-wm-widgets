-------------------------------------------------
-- Run Shell for Awesome Window Manager
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/run-shell

-- @author Pavel Makhov
-- @copyright 2018 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local gfs = require("gears.filesystem")
local wibox = require("wibox")
local gears = require("gears")
local naughty = require("naughty")
local completion = require("awful.completion")

local run_shell = awful.widget.prompt()

local w = wibox {
    visible = false,
    ontop = true,
    height = 1060,
    width = 1920
}

w:setup {
    {
        {
            {
                {
                    text = '',
                    font = 'Play 18',
                    widget = wibox.widget.textbox,
                },
                id = 'icon',
                top = 9,
                left = 10,
                layout = wibox.container.margin
            },
            {
                run_shell,
                left = 10,
                layout = wibox.container.margin,
            },
            id = 'left',
            layout = wibox.layout.fixed.horizontal
        },
        widget = wibox.container.background,
        bg = '#333333',
        shape = function(cr, width, height)
            gears.shape.rounded_rect(cr, width, height, 3)
        end,
        shape_border_color = '#74aeab',
        shape_border_width = 1,
        forced_width = 200,
        forced_height = 50
    },
    layout = wibox.container.place
}

local function launch(s)
    awful.spawn.with_line_callback(os.getenv("HOME") .. "/.config/awesome/awesome-wm-widgets/run-shell/scratch_6.sh " .. tostring(awful.screen.focused().geometry.x), {
        stdout = function(line)
            w.visible = true
            w.bgimage = '/tmp/i3lock-' .. line .. '.png'
            awful.placement.top(w, { margins = { top = 20 }, parent = awful.screen.focused() })
            awful.prompt.run {
                prompt = "<b>Run</b>: ",
                bg_cursor = '#74aeab',
                textbox = run_shell.widget,
                completion_callback = completion.shell,
                exe_callback = function(...)
                    run_shell:spawn_and_handle_error(...)
                end,
                history_path = gfs.get_cache_dir() .. "/history",
                done_callback = function()
                    --                    w.bgimage=''
                    w.visible = false
                    awful.spawn([[bash -c 'rm -f /tmp/i3lock*']])
                end
            }
        end,
        stderr = function(line)
            naughty.notify { text = "ERR:" .. line }
        end,
    })
end

return {
    launch = launch
}
