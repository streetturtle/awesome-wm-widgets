local awful = require("awful")
local spawn = require("awful.spawn")

local function Controller(view, model)
    local controller = {}

    function controller.notify_default_changed(vol, is_muted)
        view.set_widget_state(vol, is_muted)
        if view.popup.visible and controller.current_default_device then
            view.set_popup_device_state(controller.current_default_device, vol, is_muted, true)
        end
    end

    function controller.notify_device_changed(device_name, vol, is_muted, is_default)
        view.set_popup_device_state(device_name, vol, is_muted, is_default)
        if is_default then
            view.set_widget_state(vol, is_muted)
        end
    end

    function controller.notify_popup_rebuild_required()
        view.rebuild_popup()
    end

    function controller.update_default()
        spawn.easy_async(model:get_volume_cmd(), function(stdout)
            local vol, mute = model:parse_volume_cmd(stdout)
            controller.notify_default_changed(vol, mute)
        end)
    end

    function controller.action_inc_default()
        model:inc_volume()
    end

    function controller.action_dec_default()
        model:dec_volume()
    end

    function controller.action_toggle_default()
        model:tog_volume()
    end

    function controller.action_inc_device(device_name, device_type, is_default)
        if model.row_volume_up then
            model:row_volume_up(device_type, device_name, is_default)
        end
    end

    function controller.action_dec_device(device_name, device_type, is_default)
        if model.row_volume_down then
            model:row_volume_down(device_type, device_name, is_default)
        end
    end

    function controller.action_toggle_device(device_name, device_type, is_default)
        if model.row_mute_toggle then
            model:row_mute_toggle(device_type, device_name, is_default)
        end
    end

    function controller.action_set_default(device_name, device_type)
        if model.set_default then
            model:set_default(device_type, device_name)
        end
    end

    function controller.action_move_sink_inputs(device_name)
        awful.spawn.easy_async(model.LIST_SINK_INPUTS_CMD, function(stdout)
            for line in stdout:gmatch("[^\n]+") do
                local sink_id = string.match(line, "^Sink Input #(%d+)")
                if sink_id then
                    awful.spawn(model:move_sink_inputs_cmd(sink_id, device_name))
                end
            end
        end)
    end

    function controller.action_mixer(mixer_cmd)
        spawn.easy_async(mixer_cmd)
    end

    function controller.action_toggle_popup()
        if view.popup.visible then
            view.popup.visible = false
        else
            view.rebuild_popup(function()
                local mouse = mouse or require("mouse")
                view.popup:move_next_to(mouse.current_widget_geometry)
            end)
        end
    end

    return controller
end

return Controller