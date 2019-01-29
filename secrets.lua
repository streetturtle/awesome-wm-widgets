-------------------------------------------------
-- Allows to store client specific settings in one place
--
-- @author Pavel Makhov
-- @copyright 2019 Pavel Makhov
--------------------------------------------

local secrets = {
    -- Yandex.Translate API key - https://tech.yandex.com/translate/
    translate_widget_api_key = 'API_KEY',

    -- OpenWeatherMap API key - https://openweathermap.org/appid
    weather_widget_api_key = 'API_KEY',
    weather_widget_city = 'Montreal,ca',
    weather_widget_units = 'metric' -- for celsius, or 'imperial' for fahrenheit
}

return secrets
