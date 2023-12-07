local wibox = require("wibox")
local awful = require("awful")
local naughty = require("naughty")
local watch = require("awful.widget.watch")

local currentPath = debug.getinfo(1, "S").source:sub(2):match("(.*/)")

local email_widget = wibox.widget.textbox()
email_widget:set_font('Play 9')
email_widget:set_text("Loading...")


local path_to_python_in_venv = currentPath .. "/.venv/bin/python"

watch(
    path_to_python_in_venv.." "..currentPath.."count_unread_emails.py", 20,    function(_, stdout)
        local is_error = (stdout:match("ERROR") ~= nil)
        email_widget:set_text("status: "..tostring(is_error))
        if is_error then
            email_widget:set_text(stdout)
            return
        end
        local unread_emails_num = tonumber(stdout) or 0
        if (unread_emails_num > 0) then
	        email_widget:set_text(unread_emails_num)
        elseif (unread_emails_num == 0) then
            email_widget:set_text("")
        end
    end
)
local function show_emails()
    awful.spawn.easy_async(
        path_to_python_in_venv.." "..currentPath.."read_unread_emails.py",
          function(stdout)
            naughty.notify{
                text = stdout,
                title = "Unread Emails",
                timeout = 10, hover_timeout = 0.5,
                width = 800,
                parse = true,
            }
        end
    )
end

email_widget:connect_signal("mouse::enter", function() show_emails() end)

-- show_emails()
return email_widget