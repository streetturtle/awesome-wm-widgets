-------------------------------------------------
-- Weather Widget based on the OpenWeatherMap
-- https://openweathermap.org/
--
-- @author Pavel Makhov
-- @copyright 2018 Pavel Makhov
-------------------------------------------------

local http = require("socket.http")
local json = require("json")
local naughty = require("naughty")
local wibox = require("wibox")
local gears = require("gears")

local secrets = require("awesome-wm-widgets.secrets")

local path_to_icons = "/usr/share/icons/Arc/status/symbolic/"

local icon_widget = wibox.widget {
    {
        id = "icon",
        resize = false,
        widget = wibox.widget.imagebox,
    },
    layout = wibox.container.margin(_ , 0, 0, 3),
    set_image = function(self, path)
        self.icon.image = path
    end,
}

local temp_widget = wibox.widget{
    font = "Play 9",
    widget = wibox.widget.textbox,
}

local weather_widget = wibox.widget {
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

local weather_timer = gears.timer({ timeout = 60 })
local resp

weather_timer:connect_signal("timeout", function ()
    local resp_json, status = http.request('https://api.openweathermap.org/data/2.5/weather?q='
            .. secrets.weather_widget_city
            .. '&appid=' .. secrets.weather_widget_api_key
            .. '&units=' .. secrets.weather_widget_units)
    if (status ~= 200) then
        local err_resp = json.decode(resp_json)
        naughty.notify{
            title = 'Weather Widget Error',
            text = err_resp.message,
            preset = naughty.config.presets.critical,
        }
    elseif (resp_json ~= nil) then
        resp = json.decode(resp_json)
        icon_widget.image = path_to_icons .. icon_map[resp.weather[1].icon]
        temp_widget:set_text(string.gsub(resp.main.temp, "%.%d+", "")
                .. '°'
                .. (secrets.weather_widget_units == 'metric' and 'C' or 'F'))
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
            '<b>Temperature:</b> ' .. resp.main.temp .. '°'
                    .. (secrets.weather_widget_units == 'metric' and 'C' or 'F') .. '<br>' ..
            '<b>Pressure:</b> ' .. resp.main.pressure .. 'hPa<br>' ..
            '<b>Clouds:</b> ' .. resp.clouds.all .. '%<br>' ..
            '<b>Wind:</b> ' .. resp.wind.speed .. 'm/s (' .. to_direction(resp.wind.deg) .. ')',
        timeout = 5, hover_timeout = 10,
        width = 200
    }
end)

weather_widget:connect_signal("mouse::leave", function()
    naughty.destroy(notification)
end)

return weather_widget
