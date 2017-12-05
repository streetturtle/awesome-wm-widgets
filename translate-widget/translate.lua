package.path = package.path .. ";../../secrets.lua"
local secrets = require("secrets")
local awful = require("awful")
local json = require("json")
local https = require("ssl.https")
local wibox = require("wibox")
local capi = {keygrabber = keygrabber }

local api_key = secrets.translate_widget_api_key
local base_url = 'https://translate.yandex.net/api/v1.5/tr.json/translate'

-- extracts string for translation and langs
local function extract(input_string)
    local word, lang = input_string:match('^(.+)%s(%a%a%a%a)$')

    if word ~= nill and lang ~= nill then
        lang = lang:sub(1, 2) .. '-' .. lang:sub(3)
    end
    return word, lang
end

-- replaces spaces with '+' sign
local function urlencode(str)
    if (str) then
        str = string.gsub(str, " ", "+")
    end
    return str
end

local translate_widget = wibox.widget {
    {
        image  = '/usr/share/icons/Papirus-Dark/48x48/apps/gnome-translate.svg',
        resize = false,
        widget = wibox.widget.imagebox
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
        layout = wibox.layout.flex.vertical
    },
    layout  = wibox.layout.fixed.horizontal
}

local function translate(request_string)
    local to_translate, lang = extract(request_string)
    local urll = base_url .. '?lang=' .. lang .. '&text=' .. urlencode(to_translate) .. '&key=' .. api_key

    local resp_json, code = https.request(urll)
    if (code == 200 and resp_json ~= nil) then
        local resp = json.decode(resp_json).text[1]

        translate_widget.text.header:set_markup('<big>' .. lang.. '</big>')
        translate_widget.text.src:set_markup('<span color="#FFFFFF"> ' .. to_translate .. '</span>')
        translate_widget.text.res:set_markup('<span color="#FFFFFF"> ' .. resp .. '</span>')

        local w = wibox {
            width = 300,
            height = 80,
            ontop = true,
            screen = mouse.screen,
            expand = true,
            widget = translate_widget
        }
        awful.placement.top(w, { margins = {top = 25}})
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
