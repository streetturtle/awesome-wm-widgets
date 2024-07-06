-------------------------------------------------
-- Weather Widget based on the WeatherAPI
-- https://weatherapi.com/
--
-- @author Pavel Makhov
-- @copyright 2020 Pavel Makhov
-- @copyright 2024 André Jaenisch
-------------------------------------------------
local awful = require("awful")
local watch = require("awful.widget.watch")
local json = require("json")
local naughty = require("naughty")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")

local HOME_DIR = os.getenv("HOME")
local WIDGET_DIR = HOME_DIR .. '/.config/awesome/awesome-wm-widgets/weather-widget'
local GET_FORECAST_CMD = [[bash -c "curl -s --show-error -X GET '%s'"]]

local SYS_LANG = os.getenv("LANG"):sub(1, 2)
if SYS_LANG == "C" or SYS_LANG == "C." then
    -- C-locale is a common fallback for simple English
    SYS_LANG = "en"
end
-- default language is ENglish
local LANG = gears.filesystem.file_readable(WIDGET_DIR .. "/" .. "locale/" ..
                                      SYS_LANG .. ".lua") and SYS_LANG or "en"
local LCLE = require("awesome-wm-widgets.weather-widget.locale." .. LANG)
-- WeatherAPI supports only these according to https://www.weatherapi.com/docs/
-- ar, bn, bg, zh, zh_tw, cs, da, nl, fi, fr, de, el, hi, hu, it, ja, jv, ko,
-- zh_cmn, mr, pl, pt, pa, ro, ru, sr, si, sk, es, sv, ta, te, tr, uk, ur, vi,
-- zh_wuu, zh_hsn, zh_yue, zu


local function show_warning(message)
    naughty.notify {
        preset = naughty.config.presets.critical,
        title = LCLE.warning_title,
        text = message
    }
end

if SYS_LANG ~= LANG then
    show_warning("Your language is not supported yet. Language set to English")
end

local weather_widget = {}
local warning_shown = false
local tooltip = awful.tooltip {
    mode = 'outside',
    preferred_positions = {'bottom'}
}

local weather_popup = awful.popup {
    ontop = true,
    visible = false,
    shape = gears.shape.rounded_rect,
    border_width = 1,
    border_color = beautiful.bg_focus,
    maximum_width = 400,
    offset = {y = 5},
    hide_on_right_click = true,
    widget = {}
}

--- Maps WeatherAPI condition code to file name w/o extension
--- See https://www.weatherapi.com/docs/#weather-icons
local icon_map = {
    [1000] = "clear-sky",
    [1003] = "few-clouds",
    [1006] = "scattered-clouds",
    [1009] = "scattered-clouds",
    [1030] = "mist",
    [1063] = "rain",
    [1066] = "snow",
    [1069] = "rain",
    [1072] = "snow",
    [1087] = "thunderstorm",
    [1114] = "snow",
    [1117] = "snow",
    [1135] = "mist",
    [1147] = "mist",
    [1150] = "snow",
    [1153] = "snow",
    [1168] = "snow",
    [1171] = "snow",
    [1180] = "rain",
    [1183] = "rain",
    [1186] = "rain",
    [1189] = "rain",
    [1192] = "rain",
    [1195] = "rain",
    [1198] = "rain",
    [1201] = "rain",
    [1204] = "snow",
    [1207] = "snow",
    [1210] = "snow",
    [1213] = "snow",
    [1216] = "snow",
    [1219] = "snow",
    [1222] = "snow",
    [1225] = "snow",
    [1237] = "snow",
    [1240] = "rain",
    [1243] = "rain",
    [1246] = "rain",
    [1249] = "snow",
    [1252] = "snow",
    [1255] = "snow",
    [1258] = "snow",
    [1261] = "snow",
    [1264] = "snow",
    [1273] = "thunderstorm",
    [1276] = "thunderstorm",
    [1279] = "thunderstorm",
    [1282] = "thunderstorm"
}

--- Convert degrees Celsius to Fahrenheit
local function celsius_to_fahrenheit(c) return c * 9 / 5 + 32 end

-- Convert degrees Fahrenheit to Celsius
local function fahrenheit_to_celsius(f) return (f - 32) * 5 / 9 end

local function gen_temperature_str(temp, fmt_str, show_other_units, units)
    local temp_str = string.format(fmt_str, temp)
    local s = temp_str .. '°' .. (units == 'metric' and 'C' or 'F')

    if (show_other_units) then
        local temp_conv, units_conv
        if (units == 'metric') then
            temp_conv = celsius_to_fahrenheit(temp)
            units_conv = 'F'
        else
            temp_conv = fahrenheit_to_celsius(temp)
            units_conv = 'C'
        end

        local temp_conv_str = string.format(fmt_str, temp_conv)
        s = s .. ' ' .. '(' .. temp_conv_str .. '°' .. units_conv .. ')'
    end
    return s
end

local function uvi_index_color(uvi)
    local color
    if uvi >= 0 and uvi < 3 then color = '#a3be8c'
    elseif uvi >= 3 and uvi < 6 then color = '#ebcb8b'
    elseif uvi >= 6 and uvi < 8 then color = '#d08770'
    elseif uvi >= 8 and uvi < 11 then color = '#bf616a'
    elseif uvi >= 11 then color = '#b48ead'
    end

    return '<span weight="bold" foreground="' .. color .. '">' .. uvi .. '</span>'
end

local function worker(user_args)

    local args = user_args or {}

    --- Validate required parameters
    if args.coordinates == nil or args.api_key == nil then
        show_warning(LCLE.parameter_warning ..
                     (args.coordinates == nil and '<b>coordinates</b>' or '') ..
                     (args.api_key == nil and ', <b>api_key</b> ' or ''))
        return
    end

    local coordinates = args.coordinates
    local api_key = args.api_key
    local font_name = args.font_name or beautiful.font:gsub("%s%d+$", "")
    local units = args.units or 'metric'
    local both_units_widget = args.both_units_widget or false
    local icon_pack_name = args.icons or 'weather-underground-icons'
    local icons_extension = args.icons_extension or '.png'
    local timeout = args.timeout or 120

    local ICONS_DIR = WIDGET_DIR .. '/icons/' .. icon_pack_name .. '/'
        local weather_api =
        ('https://api.weatherapi.com/v1/current.json' ..
            '?q=' .. coordinates[1] .. ',' .. coordinates[2] .. '&key=' .. api_key ..
            '&units=' .. units .. '&lang=' .. LANG)

    weather_widget = wibox.widget {
        {
            {
                {
                    {
                        id = 'icon',
                        resize = true,
                        widget = wibox.widget.imagebox
                    },
                    valign = 'center',
                    widget = wibox.container.place,
                },
                {
                    id = 'txt',
                    widget = wibox.widget.textbox
                },
                layout = wibox.layout.fixed.horizontal,
            },
            left = 4,
            right = 4,
            layout = wibox.container.margin
        },
        shape = function(cr, width, height)
            gears.shape.rounded_rect(cr, width, height, 4)
        end,
        widget = wibox.container.background,
        set_image = function(self, path)
            self:get_children_by_id('icon')[1].image = path
        end,
        set_text = function(self, text)
            self:get_children_by_id('txt')[1].text = text
        end,
        is_ok = function(self, is_ok)
            if is_ok then
                self:get_children_by_id('icon')[1]:set_opacity(1)
                self:get_children_by_id('icon')[1]:emit_signal('widget:redraw_needed')
            else
                self:get_children_by_id('icon')[1]:set_opacity(0.2)
                self:get_children_by_id('icon')[1]:emit_signal('widget:redraw_needed')
            end
        end
    }

    local current_weather_widget = wibox.widget {
        {
            {
                {
                    id = 'icon',
                    resize = true,
                    forced_width = 128,
                    forced_height = 128,
                    widget = wibox.widget.imagebox
                },
                align = 'center',
                widget = wibox.container.place
            },
            {
                id = 'description',
                font = font_name .. ' 10',
                align = 'center',
                widget = wibox.widget.textbox
            },
            forced_width = 128,
            layout = wibox.layout.align.vertical
        },
        {
            {
                {
                    id = 'temp',
                    font = font_name .. ' 36',
                    widget = wibox.widget.textbox
                },
                {
                    id = 'feels_like_temp',
                    align = 'center',
                    font = font_name .. ' 9',
                    widget = wibox.widget.textbox
                },
                layout = wibox.layout.fixed.vertical
            },
            {
                {
                    id = 'wind',
                    font = font_name .. ' 9',
                    widget = wibox.widget.textbox
                },
                {
                    id = 'humidity',
                    font = font_name .. ' 9',
                    widget = wibox.widget.textbox
                },
                {
                    id = 'uv',
                    font = font_name .. ' 9',
                    widget = wibox.widget.textbox
                },
                expand = 'inside',
                layout = wibox.layout.align.vertical
            },
            spacing = 16,
            forced_width = 150,
            layout = wibox.layout.fixed.vertical
        },
        forced_width = 300,
        layout = wibox.layout.flex.horizontal,
        update = function(self, weather)
            self:get_children_by_id('icon')[1]:set_image(
                ICONS_DIR .. icon_map[weather.condition.code] .. icons_extension)
            self:get_children_by_id('temp')[1]:set_text(gen_temperature_str(weather.temp_c, '%.0f', false, units))
            self:get_children_by_id('feels_like_temp')[1]:set_text(
                LCLE.feels_like .. gen_temperature_str(weather.feelslike_c, '%.0f', false, units))
            self:get_children_by_id('description')[1]:set_text(weather.condition.text)
            self:get_children_by_id('wind')[1]:set_markup(
                LCLE.wind .. '<b>' .. weather.wind_kph .. 'km/h (' .. weather.wind_dir .. ')</b>')
            self:get_children_by_id('humidity')[1]:set_markup(LCLE.humidity .. '<b>' .. weather.humidity .. '%</b>')
            self:get_children_by_id('uv')[1]:set_markup(LCLE.uv .. uvi_index_color(weather.uv))
        end
    }

    local function update_widget(widget, stdout, stderr)
        if stderr ~= '' then
            if not warning_shown then
                if (stderr ~= 'curl: (52) Empty reply from server'
                and stderr ~= 'curl: (28) Failed to connect to api.weatherapi.com port 443: Connection timed out'
                and stderr:find('^curl: %(18%) transfer closed with %d+ bytes remaining to read$') ~= nil
                ) then
                    show_warning(stderr)
                end
                warning_shown = true
                widget:is_ok(false)
                tooltip:add_to_object(widget)

                widget:connect_signal('mouse::enter', function() tooltip.text = stderr end)
            end
            return
        end

        if string.match(stdout, '<') ~= nil then
            if not warning_shown then
                warning_shown = true
                widget:is_ok(false)
                tooltip:add_to_object(widget)

                widget:connect_signal('mouse::enter', function() tooltip.text = stdout end)
            end
            return
        end

        warning_shown = false
        tooltip:remove_from_object(widget)
        widget:is_ok(true)

        local result = json.decode(stdout)
        widget:set_image(ICONS_DIR .. icon_map[result.current.condition.code] .. icons_extension)
        -- TODO: if units isn't "metric", read temp_f instead
        widget:set_text(gen_temperature_str(result.current.temp_c, '%.0f', both_units_widget, units))

        current_weather_widget:update(result.current)

        local final_widget = {
            current_weather_widget,
            spacing = 16,
            layout = wibox.layout.fixed.vertical
        }

        weather_popup:setup({
            {
                final_widget,
                margins = 10,
                widget = wibox.container.margin
            },
            bg = beautiful.bg_normal,
            widget = wibox.container.background
        })
    end

    weather_widget:buttons(gears.table.join(awful.button({}, 1, function()
        if weather_popup.visible then
            weather_widget:set_bg('#00000000')
            weather_popup.visible = not weather_popup.visible
        else
            weather_widget:set_bg(beautiful.bg_focus)
            weather_popup:move_next_to(mouse.current_widget_geometry)
        end
    end)))

    watch(
        string.format(GET_FORECAST_CMD, weather_api),
        timeout,  -- API limit is 1k req/day; day has 1440 min; every 2 min is good
        update_widget, weather_widget
    )

    return weather_widget
end

return setmetatable(weather_widget, {__call = function(_, ...) return worker(...) end})
