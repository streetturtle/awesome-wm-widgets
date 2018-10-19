local beautiful = require("beautiful")
local gears = require("gears")

local async = require("async")
local variables = require("variables")
local D = require("debug_util")
local multimonitor = require("multimonitor")


local wallpapers_dir = variables.config_dir .. "/wallpapers"
local wallpaper_file = variables.config_dir .. "/wallpaper"

local has_wallpapers_dir = gears.filesystem.dir_readable(wallpapers_dir)

local wallpaper = {}

function wallpaper.init()
    D.log("Init wallpapers")
    if has_wallpapers_dir then
        wallpaper.choose_wallpaper()
    elseif gears.filesystem.file_readable(wallpaper_file) then
        beautiful.wallpaper = wallpaper_file
    end

end

function wallpaper.choose_wallpaper()
    if not has_wallpapers_dir then
        return
    end

    D.log("Choosing wallpapers")
    local wallpapers = {}
    async.spawn_and_get_lines({"find", wallpapers_dir, "-type", "f"},
        function(line)
            table.insert(wallpapers, line)
        end,
        function() end,
        function()
            beautiful.wallpaper = wallpapers[math.random(#wallpapers)]
            D.log("Chosen wallpaper: " .. beautiful.wallpaper)
            for s in screen do
                wallpaper.set_wallpaper(s)
            end
        end)
end

function wallpaper.set_wallpaper(s)
    if beautiful.wallpaper then
        D.log("Set wallpaper for screen "
                .. multimonitor.get_screen_name(s) .. ": "
                .. beautiful.wallpaper)
        gears.wallpaper.maximized(beautiful.wallpaper, s, false)
    end
end

if has_wallpapers_dir then
    gears.timer.start_new(300,
        function()
            wallpaper.choose_wallpaper()
            return true
        end)
end

return wallpaper
