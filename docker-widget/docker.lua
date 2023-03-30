-------------------------------------------------
-- Docker Widget for Awesome Window Manager
-- Lists containers and allows to manage them
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/docker-widget

-- @author Pavel Makhov
-- @copyright 2020 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local spawn = require("awful.spawn")
local naughty = require("naughty")
local gears = require("gears")
local beautiful = require("beautiful")

--- Utility Function to handle alternative paths
local function script_path()
	local str = debug.getinfo(2, "S").source:sub(2)
	return str:match("(.*/)")
end

local WIDGET_DIR = script_path()
local ICONS_DIR = WIDGET_DIR .. "/icons/"

local clickable_container = require(WIDGET_DIR .. "clickable-container")

local LIST_CONTAINERS_CMD = [[bash -c "docker container ls -a -s -n %s]]
    .. [[ --format '{{.Names}}::{{.ID}}::{{.Image}}::{{.Status}}::{{.Size}}'"]]

--- Utility function to show warning messages
local function show_warning(message)
	naughty.notify({
		preset = naughty.config.presets.critical,
		title = "Docker Widget",
		text = message,
	})
end

local popup = awful.popup({
	ontop = true,
	visible = false,
	shape = gears.shape.rounded_rect,
	border_width = 1,
	border_color = beautiful.bg_focus,
	maximum_width = 400,
	offset = { y = 5 },
	widget = {},
})

local docker_widget = wibox.widget({
	{
		{
			id = "icon",
			widget = wibox.widget.imagebox,
		},
		margins = 4,
		layout = wibox.container.margin,
	},
	layout = wibox.layout.fixed.horizontal,
	set_icon = function(self, new_icon)
		self:get_children_by_id("icon")[1].image = new_icon
	end,
})

local docker_widget_button = wibox.widget({
	{
		docker_widget,
		widget = wibox.container.margin,
	},
	widget = clickable_container,
})

local parse_container = function(line)
	print(line)
	local name, id, image, status, how_long, size = line:match("(.*)::(.*)::(.*)::(%w*)(.*)::(.*)")
	local actual_status = ""
	if status == "Up" and status:find("Paused") then
		actual_status = "Paused"
	else
		actual_status = status
	end

	-- if how_long is null, then set it equal to status
	if how_long == nil then
		how_long = status
	else
		how_long = how_long:gsub("%s?%(.*%)%s?", "")
	end

	local container = {
		name = name,
		id = id,
		image = image,
		status = actual_status,
		how_long = how_long,
		size = size,
		is_up = function()
			return status == "Up"
		end,
		is_paused = function()
			return actual_status:find("Paused")
		end,
		is_exited = function()
			return status == "Exited"
		end,
	}
	return container
end

local status_to_icon_name = {
	Up = ICONS_DIR .. "play.svg",
	Exited = ICONS_DIR .. "square.svg",
	Paused = ICONS_DIR .. "pause.svg",
}

local function worker(user_args)
	local args = user_args or {}

	local icon = args.icon or ICONS_DIR .. "docker.svg"
	local number_of_containers = args.number_of_containers or -1

	docker_widget:set_icon(icon)

	local rows = {
		{ widget = wibox.widget.textbox },
		layout = wibox.layout.fixed.vertical,
	}

	local function rebuild_widget(containers, errors, _, _)
		if errors ~= "" then
			show_warning(errors)
			return
		end

		for i = 0, #rows do
			rows[i] = nil
		end

		for line in containers:gmatch("[^\r\n]+") do
			local container = parse_container(line)

			local status_icon = wibox.widget({
				image = status_to_icon_name[ container["status"] ],
				resize = false,
				widget = wibox.widget.imagebox,
			})

			local start_stop_button
			if container.is_up() or container.is_exited() then
				start_stop_button = wibox.widget({
					{
						{
							id = "icon",
							image = ICONS_DIR .. (container:is_up() and "stop-btn.svg" or "play-btn.svg"),
							opacity = 0.4,
							resize = false,
							widget = wibox.widget.imagebox,
						},
						left = 2,
						right = 2,
						layout = wibox.container.margin,
					},
					shape = gears.shape.circle,
					bg = "#00000000",
					widget = wibox.container.background,
				})
				local old_cursor, old_wibox
				start_stop_button:connect_signal("mouse::enter", function(c)
					c:set_bg("#3B4252")

					local wb = mouse.current_wibox
					old_cursor, old_wibox = wb.cursor, wb
					wb.cursor = "hand1"
					c:get_children_by_id("icon")[1]:set_opacity(1)
					c:get_children_by_id("icon")[1]:emit_signal("widget::redraw_needed")
				end)
				start_stop_button:connect_signal("mouse::leave", function(c)
					c:set_bg("#00000000")
					if old_wibox then
						old_wibox.cursor = old_cursor
						old_wibox = nil
					end
					c:get_children_by_id("icon")[1]:set_opacity(0.4)
					c:get_children_by_id("icon")[1]:emit_signal("widget::redraw_needed")
				end)

				start_stop_button:buttons(awful.util.table.join(awful.button({}, 1, function()
					local command
					if container:is_up() then
						command = "stop"
					else
						command = "start"
					end

					status_icon:set_opacity(0.2)
					status_icon:emit_signal("widget::redraw_needed")

					spawn.easy_async("docker " .. command .. " " .. container["name"], function()
						if errors ~= "" then
							show_warning(errors)
						end
						spawn.easy_async(
							string.format(LIST_CONTAINERS_CMD, number_of_containers),
							function(stdout, stderr)
								rebuild_widget(stdout, stderr)
							end
						)
					end)
				end)))
			else
				start_stop_button = nil
			end

			local pause_unpause_button
			if container.is_up() then
				pause_unpause_button = wibox.widget({
					{
						{
							id = "icon",
							image = ICONS_DIR .. (container:is_paused() and "unpause-btn.svg" or "pause-btn.svg"),
							opacity = 0.4,
							resize = false,
							widget = wibox.widget.imagebox,
						},
						left = 2,
						right = 2,
						layout = wibox.container.margin,
					},
					shape = gears.shape.circle,
					bg = "#00000000",
					widget = wibox.container.background,
				})
				local old_cursor, old_wibox
				pause_unpause_button:connect_signal("mouse::enter", function(c)
					c:set_bg("#3B4252")
					local wb = mouse.current_wibox
					old_cursor, old_wibox = wb.cursor, wb
					wb.cursor = "hand1"
					c:get_children_by_id("icon")[1]:set_opacity(1)
					c:get_children_by_id("icon")[1]:emit_signal("widget::redraw_needed")
				end)
				pause_unpause_button:connect_signal("mouse::leave", function(c)
					c:set_bg("#00000000")
					if old_wibox then
						old_wibox.cursor = old_cursor
						old_wibox = nil
					end
					c:get_children_by_id("icon")[1]:set_opacity(0.4)
					c:get_children_by_id("icon")[1]:emit_signal("widget::redraw_needed")
				end)

				pause_unpause_button:buttons(awful.util.table.join(awful.button({}, 1, function()
					local command
					if container:is_paused() then
						command = "unpause"
					else
						command = "pause"
					end

					status_icon:set_opacity(0.2)
					status_icon:emit_signal("widget::redraw_needed")

					awful.spawn.easy_async("docker " .. command .. " " .. container["name"], function(_, stderr)
						if stderr ~= "" then
							show_warning(stderr)
						end
						spawn.easy_async(
							string.format(LIST_CONTAINERS_CMD, number_of_containers),
							function(stdout, container_errors)
								rebuild_widget(stdout, container_errors)
							end
						)
					end)
				end)))
			else
				pause_unpause_button = nil
			end

			local delete_button
			if not container.is_up() then
				delete_button = wibox.widget({
					{
						{
							id = "icon",
							image = ICONS_DIR .. "trash-btn.svg",
							opacity = 0.4,
							resize = false,
							widget = wibox.widget.imagebox,
						},
						margins = 4,
						layout = wibox.container.margin,
					},
					shape = gears.shape.circle,
					bg = "#00000000",
					widget = wibox.container.background,
				})
				delete_button:buttons(awful.util.table.join(awful.button({}, 1, function()
					awful.spawn.easy_async("docker rm " .. container["name"], function(_, rm_stderr)
						if rm_stderr ~= "" then
							show_warning(rm_stderr)
						end
						spawn.easy_async(
							string.format(LIST_CONTAINERS_CMD, number_of_containers),
							function(lc_stdout, lc_stderr)
								rebuild_widget(lc_stdout, lc_stderr)
							end
						)
					end)
				end)))

				local old_cursor, old_wibox
				delete_button:connect_signal("mouse::enter", function(c)
					c:set_bg("#3B4252")
					local wb = mouse.current_wibox
					old_cursor, old_wibox = wb.cursor, wb
					wb.cursor = "hand1"
					c:get_children_by_id("icon")[1]:set_opacity(1)
					c:get_children_by_id("icon")[1]:emit_signal("widget::redraw_needed")
				end)
				delete_button:connect_signal("mouse::leave", function(c)
					c:set_bg("#00000000")
					if old_wibox then
						old_wibox.cursor = old_cursor
						old_wibox = nil
					end
					c:get_children_by_id("icon")[1]:set_opacity(0.4)
					c:get_children_by_id("icon")[1]:emit_signal("widget::redraw_needed")
				end)
			else
				delete_button = nil
			end

			local row = wibox.widget({
				{
					{
						{
							{
								status_icon,
								margins = 8,
								layout = wibox.container.margin,
							},
							valigh = "center",
							layout = wibox.container.place,
						},
						{
							{
								{
									markup = "<b>" .. container["name"] .. "</b>",
									widget = wibox.widget.textbox,
								},
								{
									text = container["size"],
									widget = wibox.widget.textbox,
								},
								{
									text = container["how_long"],
									widget = wibox.widget.textbox,
								},
								forced_width = 180,
								layout = wibox.layout.fixed.vertical,
							},
							valigh = "center",
							layout = wibox.container.place,
						},
						{
							{
								start_stop_button,
								pause_unpause_button,
								delete_button,
								layout = wibox.layout.align.horizontal,
							},
							forced_width = 90,
							valign = "center",
							haligh = "center",
							layout = wibox.container.place,
						},
						spacing = 8,
						layout = wibox.layout.align.horizontal,
					},
					margins = 8,
					layout = wibox.container.margin,
				},
				bg = beautiful.bg_normal,
				widget = wibox.container.background,
			})

			row:connect_signal("mouse::enter", function(c)
				c:set_bg(beautiful.bg_focus)
			end)
			row:connect_signal("mouse::leave", function(c)
				c:set_bg(beautiful.bg_normal)
			end)

			table.insert(rows, row)
		end

		popup:setup(rows)
	end

	docker_widget_button:buttons(awful.util.table.join(awful.button({}, 1, function()
		if popup.visible then
			popup.visible = not popup.visible
		else
			spawn.easy_async(string.format(LIST_CONTAINERS_CMD, number_of_containers), function(stdout, stderr)
				rebuild_widget(stdout, stderr)
				popup:move_next_to(mouse.current_widget_geometry)
			end)
		end
	end)))

	return docker_widget_button
end

return setmetatable(docker_widget, {
	__call = function(_, ...)
		return worker(...)
	end,
})
