-------------------------------------------------
-- Translate Widget based on the Yandex.Translate API
-- https://tech.yandex.com/translate/

-- @author Pavel Makhov
-- @copyright 2020 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local spawn = require("awful.spawn")
local capi = {keygrabber = keygrabber }
local beautiful = require("beautiful")
local json = require("json")
local naughty = require("naughty")
local wibox = require("wibox")
local gears = require("gears")
local gfs = require("gears.filesystem")

local TRANSLATE_CMD = [[bash -c 'curl -s -u "apikey:%s" -H "Content-Type: application/json"]]
    ..[[ -d '\''{"text": ["%s"], "model_id":"%s"}'\'' "%s/v3/translate?version=2018-05-01"']]
local ICON = os.getenv("HOME") .. '/.config/awesome/awesome-wm-widgets/translate-widget/gnome-translate.svg'

--- Returns two values - string to translate and direction:
-- 'dog enfr' -> 'dog', 'en-fr'
-- @param input_string user's input which consists of
-- text to translate and direction, 'dog enfr'
local function extract(input_string)
    local word, lang = input_string:match('^(.+)%s(%a%a%a%a)$')

    if word ~= nil and lang ~= nil then
        lang = lang:sub(1, 2) .. '-' .. lang:sub(3)
    end
    return word, lang
end

local function show_warning(message)
    naughty.notify{
        preset = naughty.config.presets.critical,
        title = 'Translate Shell',
        text = message}
end

local w = awful.popup {
    widget = {},
    visible = false,
    border_width = 1,
    maximum_width = 400,
    width = 400,
    border_color = '#66ccff',
    ontop = true,
    bg = beautiful.bg_normal,
    shape = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, 3)
    end,
}
awful.placement.top(w, { margins = {top = 40}})


--- Main function - takes the user input and shows the widget with translation
-- @param request_string - user input (dog enfr)
local function translate(to_translate, lang, api_key, url)

    local cmd = string.format(TRANSLATE_CMD, api_key, to_translate, lang, url)
    spawn.easy_async(cmd, function (stdout, stderr)
        if stderr ~= '' then
            show_warning(stderr)
        end

        local resp = json.decode(stdout)

        w:setup {
            {
                {
                    {
                        {
                            image  = ICON,
                            widget = wibox.widget.imagebox,
                            resize = false
                        },
                        valign = 'center',
                        layout = wibox.container.place,
                    },
                    {
                        {
                            id = 'src',
                            markup = '<b>' .. lang:sub(1,2) .. '</b>: <span color="#FFFFFF"> '
                                .. to_translate .. '</span>',
                            widget = wibox.widget.textbox
                        },
                        {
                            id = 'res',
                            markup = '<b>' .. lang:sub(4) .. '</b>: <span color="#FFFFFF"> '
                                .. resp.translations[1].translation .. '</span>',
                            widget = wibox.widget.textbox
                        },
                        id = 'text',
                        layout = wibox.layout.fixed.vertical,
                    },
                    id = 'left',
                    spacing = 8,
                    layout  = wibox.layout.fixed.horizontal
                },
                bg = beautiful.bg_normal,
                forced_width = 400,
                widget = wibox.container.background
            },
            color = beautiful.bg_normal,
            margins = 8,
            widget = wibox.container.margin
        }

        w.visible = true
        w:buttons(
            awful.util.table.join(
                awful.button({}, 1, function()
                    spawn.with_shell("echo '" .. resp.translations[1].translation .. "' | xclip -selection clipboard")
                    w.visible = false
                end),
                awful.button({}, 3, function()
                    spawn.with_shell("echo '" .. to_translate .."' | xclip -selection clipboard")
                    w.visible = false
                end)
            )
        )

        capi.keygrabber.run(function(_, key, event)
            if event == "release" then return end
            if key then
                capi.keygrabber.stop()
                w.visible = false
            end
        end)
    end)
end

local prompt = awful.widget.prompt()
local input_widget = wibox {
    visible = false,
    width = 300,
    height = 100,
    maxmimum_width = 300,
    maxmimum_height = 900,
    ontop = true,
    screen = mouse.screen,
    expand = true,
    bg = beautiful.bg_normal,
    max_widget_size = 500,
    border_width = 1,
    border_color = '#66ccff',
    shape = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, 3)
    end,
}

input_widget:setup{
    {
        prompt,
        bg = beautiful.bg_normal,
        widget = wibox.container.background
    },
    margins = 8,
    widget = wibox.container.margin
}

local function launch(user_args)

    local args = user_args or {}

    local api_key = args.api_key
    local url = args.url

    awful.placement.top(input_widget, { margins = {top = 40}, parent = awful.screen.focused()})
    input_widget.visible = true

    awful.prompt.run {
        prompt = "<b>Translate</b>: ",
        textbox = prompt.widget,
        history_path = gfs.get_dir('cache') .. '/translate_history',
        bg_cursor = '#66ccff',
        exe_callback = function(text)
            if not text or #text == 0 then return end
            local to_translate, lang = extract(text)
            if not to_translate or #to_translate==0 or not lang or #lang == 0 then
                naughty.notify({
                    preset = naughty.config.presets.critical,
                    title = 'Translate Widget Error',
                    text = 'Language is not provided',
                })
                return
            end
            translate(to_translate, lang, api_key, url)
        end,
        done_callback = function()
            input_widget.visible = false
        end
    }
end

return {
    launch = launch
}
