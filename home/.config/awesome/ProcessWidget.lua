local wibox = require("wibox")

local Process = require("Process")
local variables = require("variables")

local ProcessWidget = {}
ProcessWidget.__index = ProcessWidget
setmetatable(ProcessWidget, {
    __call = function(cls, ...)
        return cls.new(...)
    end
})

function ProcessWidget.new(name, command, not_running_icon, running_icon)
    local icon_widget = wibox.widget{
        image=not_running_icon,
        resize=true,
        widget=wibox.widget.imagebox,
    }
    local question_widget = wibox.widget{
        image=variables.config_dir .. "/question.svg",
        resize=true,
        widget=wibox.widget.imagebox,
    }
    local widget = wibox.widget{
        icon_widget,
        question_widget,
        layout=wibox.layout.stack,

        icon_widget=icon_widget,
        question_widget=question_widget,
        not_running_icon=not_running_icon,
        running_icon=running_icon,
    }

    local process = Process(name, command)
    process.state_machine:connect_signal("state_changed", function()
        local should_be_running = process:should_be_running()
        if should_be_running then
            widget.icon_widget.image = widget.running_icon
        else
            widget.icon_widget.image = widget.not_running_icon
        end

        widget.question_widget.visible =
            should_be_running ~= process:is_running()
    end)
    widget.process = process

    widget:connect_signal("button::press", function()
        widget:toggle()
    end)

    return setmetatable(widget, ProcessWidget)
end

function ProcessWidget:toggle()
    if self.process:should_be_running() then
        self.process:stop()
    else
        self.process:start()
    end
end

return ProcessWidget
