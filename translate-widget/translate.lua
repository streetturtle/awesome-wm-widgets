-------------------------------------------------
-- Translate Widget based on the Yandex.Translate API
-- https://tech.yandex.com/translate/

-- @author Pavel Makhov
-- @copyright 2018 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local capi = {keygrabber = keygrabber }
local https = require("ssl.https")
local json = require("json")
local naughty = require("naughty")
local wibox = require("wibox")
local gears = require("gears")
local gfs = require("gears.filesystem")

local BASE_URL = 'https://translate.yandex.net/api/v1.5/tr.json/translate'
local ICON = '/usr/share/icons/Papirus-Dark/48x48/apps/gnome-translate.svg'

--- Returns two values - string to translate and direction:
-- 'dog enfr' -> 'dog', 'en-fr'
-- @param input_string user's input which consists of
-- text to translate and direction, 'dog enfr'
local function extract(input_string)
    local word, lang = input_string:match('^(.+)%s(%a%a%a%a)$')

    if word ~= nill and lang ~= nill then
        lang = lang:sub(1, 2) .. '-' .. lang:sub(3)
    end
    return word, lang
end

--- Simple url encoder - replaces spaces with '+' sign
-- @param url to encode
local function urlencode(url)
    if (url) then
        url = string.gsub(url, " ", "+")
    end
    return url
end

local w = wibox {
    width = 300,
    border_width = 1,
    border_color = '#66ccff',
    ontop = true,
    expand = true,
    bg = '#1e252c',
    max_widget_size = 500,
    shape = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, 3)
    end

}

w:setup {
    {
        {
            image  = ICON,
            widget = wibox.widget.imagebox,
            resize = false
        },
        id = 'img',
        layout = wibox.container.margin(_, 0, 0, 10)
    },
    {
        {
            id = 'header',
            widget = wibox.widget.textbox
        },
        {
            id = 'src',
            widget = wibox.widget.textbox
        },
        {
            id = 'res',
            widget = wibox.widget.textbox
        },
        id = 'text',
        layout = wibox.layout.fixed.vertical,
    },
    id = 'left',
    layout  = wibox.layout.fixed.horizontal
}

--- Main function - takes the user input and shows the widget with translation
-- @param request_string - user input (dog enfr)
local function translate(to_translate, lang, api_key)
    local urll = BASE_URL .. '?lang=' .. lang .. '&text=' .. urlencode(to_translate) .. '&key=' .. api_key

    local resp_json, code = https.request(urll)
    if (code == 200 and resp_json ~= nil) then
        local resp = json.decode(resp_json).text[1]

        w.left.text.header:set_markup('<big>' .. lang .. '</big>')
        w.left.text.src:set_markup('<b>' .. lang:sub(1,2) .. '</b>: <span color="#FFFFFF"> ' .. to_translate .. '</span>')
        w.left.text.res:set_markup('<b>' .. lang:sub(4) .. '</b>: <span color="#FFFFFF"> ' .. resp .. '</span>')

        awful.placement.top(w, { margins = {top = 40}})

        local h1 = w.left.text.header:get_height_for_width(w.width, w.screen)
        local h2 = w.left.text.src:get_height_for_width(w.width, w.screen)
        local h3 = w.left.text.res:get_height_for_width(w.width, w.screen)

        -- calculate height of the widget
        w.height = h1 + h2 + h3 + 20
        -- try to vertically align the icon
        w.left.img:set_top((h1 + h2 + h3 + 20 - 48)/2)

        w.visible = true
        w:buttons(
            awful.util.table.join(
                awful.button({}, 1, function()
                    awful.spawn.with_shell("echo '" .. resp .. "' | xclip -selection clipboard")
                    w.visible = false
                end),
                awful.button({}, 3, function()
                    awful.spawn.with_shell("echo '" .. to_translate .."' | xclip -selection clipboard")
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
    else
        naughty.notify({
            preset = naughty.config.presets.critical,
            title = 'Translate Widget Error',
            text = resp_json,
        })
    end
end

local input_widget = wibox {
    width = 300,
    ontop = true,
    screen = mouse.screen,
    expand = true,
    bg = '#1e252c',
    max_widget_size = 500,
    border_width = 1;
    border_width = 1,
    border_color = '#66ccff',
    shape = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, 3)
    end
}

local prompt = awful.widget.prompt()

input_widget:setup {
    layout = wibox.container.margin,
    prompt,
    left = 10
}

local function show_translate_prompt(api_key)
    awful.placement.top(input_widget, { margins = {top = 40}, parent = awful.screen.focused()})
    input_widget.height = 40
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
            translate(to_translate, lang, api_key)
        end,
        done_callback = function()
            input_widget.visible = false
        end
    }
end

return {
    show_translate_prompt = show_translate_prompt
}
