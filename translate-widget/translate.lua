package.path = package.path .. ";../../secrets.lua"
local secrets = require("secrets")
local awful = require("awful")
local gears = require("gears")
local json = require("json")
local https = require("ssl.https")
local wibox = require("wibox")

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
    forced_num_cols = 1,
    forced_num_rows = 3,
    homogeneous = true,
    expand = true,
    vertical_spacing = 5,
    horizontal_expand = true,
    vertical_expand = true,
    layout = wibox.layout.grid
}

local lang_wdgt = wibox.widget{
    widget = wibox.widget.textbox,
    align  = 'center',
    valign = 'center'
}

local to_translate_wdgt = wibox.widget{
    widget = wibox.widget.textbox,
    align  = 'center',
    valign = 'center'
}

local translation_wdgt = wibox.widget{
    widget = wibox.widget.textbox,
    align  = 'center',
    valign = 'center'
}

translate_widget:add_widget_at(lang_wdgt, 1,1,1,1)
translate_widget:add_widget_at(to_translate_wdgt, 2,1,1,1)
translate_widget:add_widget_at(translation_wdgt, 3,1,1,1)

local function translate(request_string)
    local to_translate, lang = extract(request_string)
    local urll = base_url .. '?lang=' .. lang .. '&text=' .. urlencode(to_translate) .. '&key=' .. api_key

    local resp_json, code = https.request(urll)
    if (code == 200 and resp_json ~= nil) then
        local resp = json.decode(resp_json).text[1]

        lang_wdgt:set_markup('<big>' .. lang.. '</big>')
        to_translate_wdgt:set_text(to_translate)
        translation_wdgt:set_text(resp)

        local w = wibox {
            width = 300,
            height = 50,
            ontop = true,
            screen = mouse.screen,
            shape_clip = true,
            shape = gears.shape.rounded_rect,
            widget = translate_widget
        }
        awful.placement.top_right(w, { margins = {top = 25}})
        w.visible = true
        w:buttons(
            awful.util.table.join(
                awful.button({}, 1, function() awful.spawn.with_shell("echo left | xsel --clipboard")
                    w.visible = false
                end),
                awful.button({}, 3, function()
                    awful.spawn.with_shell("echo right | xsel --clipboard")
                    w.visible = false
                end)
            )
        )
    end
end

return {
    translate = translate
}
