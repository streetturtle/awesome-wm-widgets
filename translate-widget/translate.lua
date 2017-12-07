-------------------------------------------------
-- Translate Widget

-- @author Pavel Makhov
-- @copyright 2017 Pavel Makhov
-------------------------------------------------

package.path = package.path .. ";../../secrets.lua"
local secrets = require("secrets")

local awful = require("awful")
local capi = {keygrabber = keygrabber }
local https = require("ssl.https")
local json = require("json")
local wibox = require("wibox")

local API_KEY = secrets.translate_widget_api_key
local BASE_URL = 'https://translate.yandex.net/api/v1.5/tr.json/translate'

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
    ontop = true,
    screen = mouse.screen,
    expand = true,
    bg = '#1e252c',
    max_widget_size = 500
}

w:setup {
    {
        {
            image  = '/usr/share/icons/Papirus-Dark/48x48/apps/gnome-translate.svg',
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

--- Main function - takes the user input and shows the widget with translations
local function translate(request_string)
    local to_translate, lang = extract(request_string)
    local urll = BASE_URL .. '?lang=' .. lang .. '&text=' .. urlencode(to_translate) .. '&key=' .. API_KEY

    local resp_json, code = https.request(urll)
    if (code == 200 and resp_json ~= nil) then
        local resp = json.decode(resp_json).text[1]

        w.left.text.header:set_markup('<big>' .. lang .. '</big>')
        w.left.text.src:set_markup('<b>' .. lang:sub(1,2) .. '</b>: <span color="#FFFFFF"> ' .. to_translate .. '</span>')
        w.left.text.res:set_markup('<b>' .. lang:sub(4) .. '</b>: <span color="#FFFFFF"> ' .. resp .. '</span>')

        awful.placement.top(w, { margins = {top = 25}})

        local h1 = w.left.text.header:get_height_for_width(w.width, w.screen)
        local h2 = w.left.text.src:get_height_for_width(w.width, w.screen)
        local h3 = w.left.text.res:get_height_for_width(w.width, w.screen)

        w.height = h1 + h2 + h3 + 20
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
    end
end

return {
    translate = translate
}
