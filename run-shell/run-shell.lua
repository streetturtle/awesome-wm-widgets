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
local naughty = require("naughty")
local completion = require("awful.completion")

local spotify_shell = awful.widget.prompt()

local w = wibox{
    --    bg = '#1e252c55',
    --    bgimage = '/home/pmakhov/.config/awesome/themes/awesome-darkspace/somecity.jpg',
    visible = false,
    border_width = 1,
    border_color = '#333333',
    max_widget_size = 500,
    ontop = true,
    --    height = 50,
    --    width = 250,
    height = 1060,
    width = 1920,
    shape = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, 3)
    end
}

w:setup {
    {
        {
            text = '',
            font = 'Play 20',
            widget = wibox.widget.textbox,
        },
        id = 'icon',
        top = 9,
        left = 10,
        layout = wibox.container.margin
    },
    {
        --        {
        layout = wibox.container.margin,
        left = 10,
        spotify_shell,
    },
    id = 'left',
    layout = wibox.layout.fixed.horizontal
}

local function launch(s)

    awful.spawn.with_line_callback(os.getenv("HOME") .. "/.config/awesome/awesome-wm-widgets/run-shell/scratch_6.sh", {
        stdout = function(line)
            w.visible = true
--            naughty.notify { text = "LINE:" .. line }
            w.bgimage = '/tmp/i3lock' .. line.. '.png'
            awful.placement.top(w, { margins = { top = 20 }, parent = awful.screen.focused() })
            awful.prompt.run {
                prompt = "<b>Run</b>: ",
                bg_cursor = '#74aeab',
                textbox = spotify_shell.widget,
                completion_callback = completion.shell,
                exe_callback = function(...)
                    spotify_shell:spawn_and_handle_error(...)
                end,
                history_path = gfs.get_cache_dir() .. "/history",
                done_callback = function()
                    w.bgimage=''
                    w.visible = false
                    awful.spawn(os.getenv("HOME") .. '/.IntelliJIdea2018.2/config/scratches/scratch_7.sh')
                end
            }
        end,
        stderr = function(line)
            naughty.notify { text = "ERR:" .. line }
        end,
    })

    --    w.bgimage = '/home/pmakhov/.config/awesome/themes/awesome-darkspace/somecity.jpg'
    --    w.bg = '#333333',

    --    w.visible = true
    --    awful.placement.top(w, { margins = { top = 400 }, parent = awful.screen.focused() })
    --    awful.prompt.run {
    --        prompt = "<b>Run</b>: ",
    --        bg_cursor = '#74aeab',
    --        textbox = spotify_shell.widget,
    --        completion_callback = completion.shell,
    --        exe_callback = function(...)
    --            spotify_shell:spawn_and_handle_error(...)
    --        end,
    --        history_path = gfs.get_cache_dir() .. "/history",
    --        done_callback = function()
    --            w.visible = false
    --        end
    --    }
end

return {
    launch = launch
}
