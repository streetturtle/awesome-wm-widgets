-------------------------------------------------
-- Weather Widget based on the OpenWeatherMap
-- https://openweathermap.org/
--
-- @author Pavel Makhov
-- @copyright 2018 Pavel Makhov
-------------------------------------------------

local socket = require("socket")
local http = require("socket.http")
local ltn12 = require("ltn12")
local json = require("json")
local naughty = require("naughty")
local wibox = require("wibox")
local gears = require("gears")

local path_to_icons = "/usr/share/icons/Arc/status/symbolic/"

local weather_widget = {}

local function worker(args)

    local args = args or {}

    local font = args.font or 'Play 9'
    local city = args.city or 'Montreal,ca'
    local api_key = args.api_key or naughty.notify{preset = naughty.config.presets.critical, text = 'OpenweatherMap API key is not set'}
    local units = args.units or 'metric'
    local both_units_widget = args.both_units_widget or false
    local both_units_popup = args.both_units_popup or false
    local position = args.notification_position or "top_right"

    local weather_api_url = (
            'https://api.openweathermap.org/data/2.5/weather'
                    .. '?q='     .. city
                    .. '&appid=' .. api_key
                    .. '&units=' .. units
    )

    local icon_widget = wibox.widget {
        {
            id = "icon",
            resize = false,
            widget = wibox.widget.imagebox,
        },
        layout = wibox.container.margin(_, 0, 0, 3),
        set_image = function(self, path)
            self.icon.image = path
        end,
    }

    local temp_widget = wibox.widget {
        font = font,
        widget = wibox.widget.textbox,
    }

    weather_widget = wibox.widget {
        icon_widget,
        temp_widget,
        layout = wibox.layout.fixed.horizontal,
    }

    --- Maps openWeatherMap icons to Arc icons
    local icon_map = {
        ["01d"] = "weather-clear-symbolic.svg",
        ["02d"] = "weather-few-clouds-symbolic.svg",
        ["03d"] = "weather-clouds-symbolic.svg",
        ["04d"] = "weather-overcast-symbolic.svg",
        ["09d"] = "weather-showers-scattered-symbolic.svg",
        ["10d"] = "weather-showers-symbolic.svg",
        ["11d"] = "weather-storm-symbolic.svg",
        ["13d"] = "weather-snow-symbolic.svg",
        ["50d"] = "weather-fog-symbolic.svg",
        ["01n"] = "weather-clear-night-symbolic.svg",
        ["02n"] = "weather-few-clouds-night-symbolic.svg",
        ["03n"] = "weather-clouds-night-symbolic.svg",
        ["04n"] = "weather-overcast-symbolic.svg",
        ["09n"] = "weather-showers-scattered-symbolic.svg",
        ["10n"] = "weather-showers-symbolic.svg",
        ["11n"] = "weather-storm-symbolic.svg",
        ["13n"] = "weather-snow-symbolic.svg",
        ["50n"] = "weather-fog-symbolic.svg"
    }

    --- Return wind direction as a string.
    local function to_direction(degrees)
        -- Ref: https://www.campbellsci.eu/blog/convert-wind-directions
        if degrees == nil then
            return "Unknown dir"
        end
        local directions = {
            "N",
            "NNE",
            "NE",
            "ENE",
            "E",
            "ESE",
            "SE",
            "SSE",
            "S",
            "SSW",
            "SW",
            "WSW",
            "W",
            "WNW",
            "NW",
            "NNW",
            "N",
        }
        return directions[math.floor((degrees % 360) / 22.5) + 1]
    end

    -- Convert degrees Celsius to Fahrenheit
    local function celsius_to_fahrenheit(c)
        return c*9/5+32
    end

    -- Convert degrees Fahrenheit to Celsius
    local function fahrenheit_to_celsius(f)
        return (f-32)*5/9
    end

    local weather_timer = gears.timer({ timeout = 60 })
    local resp

    local function gen_temperature_str(temp, fmt_str, show_other_units)
        local temp_str = string.format(fmt_str, temp)
        local s =  temp_str .. '°' .. (units == 'metric' and 'C' or 'F')

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
            s = s .. ' ' ..  '('.. temp_conv_str .. '°' .. units_conv .. ')'
        end
        return s
    end

    local function error_display(resp_json)
        local err_resp = json.decode(resp_json)
        naughty.notify{
            title = 'Weather Widget Error',
            text = err_resp.message,
            preset = naughty.config.presets.critical,
        }
    end

    weather_timer:connect_signal("timeout", function ()
        local resp_json = {}
        local res, status = http.request{
            url=weather_api_url,
            sink=ltn12.sink.table(resp_json),
            -- ref:
            -- http://w3.impa.br/~diego/software/luasocket/old/luasocket-2.0/http.html
            create=function()
                -- ref: https://stackoverflow.com/a/6021774/595220
                local req_sock = socket.tcp()
                -- 't' — overall timeout
                req_sock:settimeout(0.2, 't')
                -- 'b' — block timeout
                req_sock:settimeout(0.001, 'b')
                return req_sock
            end
        }
        if (resp_json ~= nil) then
            resp_json = table.concat(resp_json)
        end

        if (status ~= 200 and resp_json ~= nil and resp_json ~= '') then
            if (not pcall(error_display, resp_json)) then
                naughty.notify{
                    title = 'Weather Widget Error',
                    text = 'Cannot parse answer',
                    preset = naughty.config.presets.critical,
                }
            end
        elseif (resp_json ~= nil and resp_json ~= '') then
            resp = json.decode(resp_json)
            icon_widget.image = path_to_icons .. icon_map[resp.weather[1].icon]
            temp_widget:set_text(gen_temperature_str(resp.main.temp, '%.0f', both_units_widget))
        end
    end)
    weather_timer:start()
    weather_timer:emit_signal("timeout")

    --- Notification with weather information. Popups when mouse hovers over the icon
    local notification
    weather_widget:connect_signal("mouse::enter", function()
        notification = naughty.notify{
            icon = path_to_icons .. icon_map[resp.weather[1].icon],
            icon_size=20,
            text =
                '<big>' .. resp.weather[1].main .. ' (' .. resp.weather[1].description .. ')</big><br>' ..
                '<b>Humidity:</b> ' .. resp.main.humidity .. '%<br>' ..
                '<b>Temperature:</b> ' .. gen_temperature_str(resp.main.temp, '%.1f',
                                              both_units_popup) .. '<br>' ..
                '<b>Pressure:</b> ' .. resp.main.pressure .. 'hPa<br>' ..
                '<b>Clouds:</b> ' .. resp.clouds.all .. '%<br>' ..
                '<b>Wind:</b> ' .. resp.wind.speed .. 'm/s (' .. to_direction(resp.wind.deg) .. ')',
            timeout = 5, hover_timeout = 10,
            position = position,
            width = (both_units_popup == true and 210 or 200)
        }
    end)

    weather_widget:connect_signal("mouse::leave", function()
        naughty.destroy(notification)
    end)

    return weather_widget
end

return setmetatable(weather_widget, { __call = function(_, ...)
    return worker(...)
end })
