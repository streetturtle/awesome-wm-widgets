local awful = require("awful")
local wibox = require("wibox")
local spawn = require("awful.spawn")
local gears = require("gears")
local beautiful = require("beautiful")
local utils = require("awesome-wm-widgets.volume-widget.utils")

local ICON_DIR = os.getenv("HOME") .. '/.config/awesome/awesome-wm-widgets/volume-widget/icons/'

local control_apps = {
	pactl = require("awesome-wm-widgets.volume-widget.providers.pactl"),
	amixer = require("awesome-wm-widgets.volume-widget.providers.amixer"),
	wpctl = require("awesome-wm-widgets.volume-widget.providers.wpctl")
}

local volume = {}

local function worker(user_args)
	local args = user_args or {}

	local widget_types = {
		icon = require("awesome-wm-widgets.volume-widget.widgets.icon-widget"),
		icon_and_text = require("awesome-wm-widgets.volume-widget.widgets.icon-and-text-widget"),
		arc = require("awesome-wm-widgets.volume-widget.widgets.arc-widget"),
		horizontal_bar = require("awesome-wm-widgets.volume-widget.widgets.horizontal-bar-widget"),
		vertical_bar = require("awesome-wm-widgets.volume-widget.widgets.vertical-bar-widget")
	}

	local widget_type = args.widget_type or 'icon'
	volume.widget = widget_types[widget_type].get_widget(args)

	local mixer_cmd = args.mixer_cmd or 'pavucontrol'

	volume.sink_icon_map = args.sink_icon_map or {}
	volume.popup_buttons = args.popup_buttons or {
		set_default = { 1, 2 },
		move_sink_inputs = { 2 },
		volume_up = { 4 },
		volume_down = { 5 },
		mute = { 3 }
	}

	-- =========================================================================
	-- VIEW: Manages UI components and provides methods to update them
	-- =========================================================================
	local view = {
		popup = awful.popup({
			bg = beautiful.bg_normal,
			fg = beautiful.fg_normal,
			maximum_width = 400,
			offset = { y = 5 },
			ontop = true,
			shape = gears.shape.rounded_rect,
			visible = false,
			widget = {},
		}),
		popup_ui_elements = {}
	}

	local function close_popup()
		if view.popup.visible then
			view.popup.visible = false
		end
	end

	view.popup:connect_signal("property::visible", function(p)
		if p.visible then
			client.connect_signal("button::press", close_popup)
		else
			client.disconnect_signal("button::press", close_popup)
		end
	end)

	if awful.mouse.append_global_mousebinding then
		awful.mouse.append_global_mousebinding(awful.button({ }, 1, close_popup))
		awful.mouse.append_global_mousebinding(awful.button({ }, 3, close_popup))
	else
		root.buttons(gears.table.join(
			root.buttons(),
			awful.button({ }, 1, close_popup),
			awful.button({ }, 3, close_popup)
		))
	end

	function view.set_widget_state(vol, mute)
		if mute then volume.widget:mute() else volume.widget:unmute() end
		volume.widget:set_volume_level(vol)
	end

	function view.set_popup_device_state(device_name, vol, mute, is_default)
		local ui = view.popup_ui_elements[device_name]
		if ui then
			if vol then ui.arc.value = vol end
			if mute ~= nil then
				ui.arc.colors = {
					mute and beautiful.fg_badval_widget
					or is_default and beautiful.fg_goodval_widget
					or beautiful.fg_normal
				}
			end
		end
	end

	local function build_main_line(device)
		if device.properties.device_description == nil or device.properties.device_description == "null" then
			return device.name
		else
			return device.properties.device_description
		end
	end

	-- Forward declare controller for UI event handlers
	local controller = {}

    args.adapter = controller
	local control_app_factory = control_apps[args.control_app] or control_apps.amixer
	local control_app = control_app_factory.new(args)


	local function build_header_row(text)
		return wibox.widget({
			{ markup = "<b>" .. text .. "</b>", align = "center", widget = wibox.widget.textbox },
			bg = beautiful.bg_normal, fg = beautiful.fg_normal, widget = wibox.container.background,
		})
	end

	local function build_rows(devices, device_type)
		local device_rows = {}
		for _, device in ipairs(devices) do

			local volumearc = wibox.widget {
				{
					image  = volume.sink_icon_map[device.name] or ICON_DIR .. 'audio-volume-high-symbolic.svg',
					resize = true, widget = wibox.widget.imagebox
				},
				max_value = 100, thickness = 2, start_angle = 4.71238898,
				forced_height = 20, forced_width = 20,
				colors = {
					device.mute and beautiful.fg_badval_widget
					or device.is_default and beautiful.fg_goodval_widget
					or beautiful.fg_normal
				},
				paddings = 2,
				value = (device.volume and device.volume:match('(%d?%d?%d)%%')) and tonumber(device.volume:match('(%d?%d?%d)%%')) or 0,
				widget = wibox.container.arcchart,
			}

			local text_widget = wibox.widget {
				markup = (device.is_default and "<b>" or "") .. build_main_line(device) .. (device.is_default and "</b>" or ""),
				align = "left", widget = wibox.widget.textbox,
			}

			view.popup_ui_elements[device.name] = { arc = volumearc, text = text_widget }

			local row = wibox.widget({
				{
					{ volumearc, text_widget, spacing = 10, layout = wibox.layout.fixed.horizontal },
					margins = 4, layout = wibox.container.margin,
				},
				bg = beautiful.bg_normal, fg = beautiful.fg_normal, widget = wibox.container.background,
			})

			row:connect_signal("mouse::enter", function(c) c:set_fg(beautiful.fg_focus); c:set_bg(beautiful.bg_focus) end)
			row:connect_signal("mouse::leave", function(c) c:set_fg(beautiful.fg_normal); c:set_bg(beautiful.bg_normal) end)

			local old_cursor, old_wibox
			row:connect_signal("mouse::enter", function()
				local wb = mouse.current_wibox
				if wb then old_cursor, old_wibox = wb.cursor, wb; wb.cursor = "hand1" end
			end)
			row:connect_signal("mouse::leave", function()
				if old_wibox then old_wibox.cursor = old_cursor; old_wibox = nil end
			end)

			row:connect_signal("button::press", function(_, _, _, button)
				if utils.is_in(volume.popup_buttons.set_default, button) then
					controller.action_set_default(device.name, device_type)
				end
				if utils.is_in(volume.popup_buttons.move_sink_inputs, button) and device_type == "sink" then
					controller.action_move_sink_inputs(device.name)
				end
				if utils.is_in(volume.popup_buttons.volume_up, button) then
					controller.action_inc_device(device.name, device_type, device.is_default)
				end
				if utils.is_in(volume.popup_buttons.volume_down, button) then
					controller.action_dec_device(device.name, device_type, device.is_default)
				end
				if utils.is_in(volume.popup_buttons.mute, button) then
					controller.action_toggle_device(device.name, device_type, device.is_default)
				end
			end)
			table.insert(device_rows, row)
		end
		return device_rows
	end

	function view.rebuild_popup(on_complete)
		spawn.easy_async(control_app.LIST_DEVICES_CMD, function(stdout)
			local sinks, sources = control_app:extract_sinks_and_sources(stdout)
			view.popup_ui_elements = {}

			-- Track current default device
			for _, s in ipairs(sinks) do if s.is_default then controller.current_default_device = s.name end end

			local new_rows = { layout = wibox.layout.fixed.vertical }
			table.insert(new_rows, build_header_row("SINKS"))
			for _, row in ipairs(build_rows(sinks, "sink")) do table.insert(new_rows, row) end
			table.insert(new_rows, build_header_row("SOURCES"))
			for _, row in ipairs(build_rows(sources, "source")) do table.insert(new_rows, row) end

			view.popup:setup(new_rows)
			if on_complete then on_complete() end
		end)
	end

	-- =========================================================================
	-- CONTROLLER: Handles events, invokes Model actions, and updates the View
	-- =========================================================================

	function controller.update_default()
		spawn.easy_async(control_app:get_volume_cmd(), function(stdout)
			local vol, mute = control_app:parse_volume_cmd(stdout)
			view.set_widget_state(vol, mute)
			if view.popup.visible and controller.current_default_device then
				view.set_popup_device_state(controller.current_default_device, vol, mute, true)
			end
		end)
	end

	function controller.notify_default_changed(vol, is_muted)
        view.set_widget_state(vol, is_muted)
        if view.popup.visible and controller.current_default_device then
            view.set_popup_device_state(controller.current_default_device, vol, is_muted, true)
        end
	end

	function controller.update_device(device_name, device_type, is_default)
		spawn.easy_async(control_app:get_row_volume_cmd(device_type, device_name), function(stdout)
			local vol, mute = control_app:parse_row_volume(stdout)
			view.set_popup_device_state(device_name, vol, mute, is_default)
			if is_default then
				view.set_widget_state(vol, mute)
			end
		end)
	end

	function controller.action_inc_default()
		control_app:inc_volume()
	end

	function controller.action_dec_default()
		control_app:dec_volume()
	end

	function controller.action_toggle_default()
        control_app:tog_volume()
	end

	function controller.action_inc_device(device_name, device_type, is_default)
		spawn.easy_async(control_app:row_volume_up_cmd(device_type, device_name), function()
			controller.update_device(device_name, device_type, is_default)
		end)
	end

	function controller.action_dec_device(device_name, device_type, is_default)
		spawn.easy_async(control_app:row_volume_down_cmd(device_type, device_name), function()
			controller.update_device(device_name, device_type, is_default)
		end)
	end

	function controller.action_toggle_device(device_name, device_type, is_default)
		spawn.easy_async(control_app:row_mute_toggle_cmd(device_type, device_name), function()
			controller.update_device(device_name, device_type, is_default)
		end)
	end

	function controller.action_set_default(device_name, device_type)
		spawn.easy_async(control_app:set_default_cmd(device_type, device_name), function()
			controller.update_default()
			view.rebuild_popup()
		end)
	end

	function controller.action_move_sink_inputs(device_name)
		awful.spawn.easy_async(control_app.LIST_SINK_INPUTS_CMD, function(stdout)
			for line in stdout:gmatch("[^\n]+") do
				local sink_id = string.match(line, "^Sink Input #(%d+)")
				if sink_id then
					awful.spawn(control_app:move_sink_inputs_cmd(sink_id, device_name))
				end
			end
		end)
	end

	function controller.action_mixer()
		spawn.easy_async(mixer_cmd)
	end

	function controller.action_toggle_popup()
		if view.popup.visible then
			view.popup.visible = false
		else
			view.rebuild_popup(function()
				view.popup:move_next_to(mouse.current_widget_geometry)
			end)
		end
	end

	volume.widget:buttons(awful.util.table.join(
		awful.button({}, 1, controller.action_toggle_default),
		awful.button({}, 2, controller.action_mixer),
		awful.button({}, 3, controller.action_toggle_popup),
		awful.button({}, 4, controller.action_inc_default),
		awful.button({}, 5, controller.action_dec_default)
	))

	gears.timer {
		timeout = args.refresh_rate or 1,
		call_now = true,
		autostart = true,
		callback = controller.update_default
	}

	return volume.widget
end

return setmetatable(volume, { __call = function(_, ...) return worker(...) end })
