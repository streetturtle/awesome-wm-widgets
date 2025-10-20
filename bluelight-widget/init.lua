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

---@class Bluelight.Widget.Opts
---@field cmd string?
---@field night_args string[] | string?
---@field day_args string[]? | string?
---@field day_icon string?
---@field night_icon string?

---@type Bluelight.Widget.Opts
local default_opts = {
	cmd = "redshift",
	night_args = { "-O", "2500", "-g", "0.75", "-P" },
	day_args = { "-x" },
	day_icon = DAY_ICON,
	night_icon = NIGHT_ICON,
}

---@param opts Bluelight.Widget.Opts
local factory = function(opts)
	opts = opts or {}
	local cmd = opts.cmd or default_opts.cmd
	local night_args = opts.night_args or default_opts.night_args
	local day_args = opts.day_args or default_opts.day_args
	local day_icon = opts.day_icon or default_opts.day_icon
	local night_icon = opts.night_icon or default_opts.night_icon

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
			icon:set_image(day_icon)
		else
			icon:set_image(night_icon)
		end
	end

	local function on_day()
		local args = type(day_args) == "table" and table.concat(day_args, " ") or day_args
		awful.spawn(cmd .. " " .. args)
		widget:update()
	end

	local function on_night()
		local args = type(night_args) == "table" and table.concat(night_args, " ") or night_args
		awful.spawn(cmd .. " " .. args)
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
end

return factory
