-------------------------------------------------
-- Blue Light Filter Widget for Awesome Window Manager
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/bluelight-widget

-- @author VMatt
-- @copyright 2025 VMatt
-------------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local gfs = require("gears.filesystem")

local ICON_DIR = gfs.get_configuration_dir() .. "awesome-wm-widgets/bluelight-widget/"
local DAY_ICON = ICON_DIR .. "sun.svg"
local NIGHT_ICON = ICON_DIR .. "moon.svg"

local CMD = "redshift"
local NIGHT_CMD = "-O 2500 -g 0.75"
local DAY_CMD = "-x"
local day = true

local widget = wibox.widget({
	{

		{
			id = "icon",
			image = DAY_ICON,
			resize = true,
			widget = wibox.widget.imagebox,
		},
		layout = wibox.layout.fixed.horizontal,
		widget = wibox.container.margin,
	},
	border_width = 5,
	widget = wibox.container.background,
	layout = wibox.layout.fixed.horizontal,
})

function widget:update()
	local icon = self:get_children_by_id("icon")[1]
	if day then
		icon:set_image(DAY_ICON)
	else
		icon:set_image(NIGHT_ICON)
	end
end

local function on_day()
	awful.spawn(CMD .. " " .. DAY_CMD)
	widget:update()
end

local function on_night()
	awful.spawn(CMD .. " " .. NIGHT_CMD)
	widget:update()
end

local function toggle()
	day = not day
	if day then
		on_day()
	else
		on_night()
	end
end

widget:buttons(awful.util.table.join(awful.button({}, 1, function()
	toggle()
end)))

return widget
