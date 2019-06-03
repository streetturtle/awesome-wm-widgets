-------------------------------------------------
-- Allows to store client specific settings in one place
--
-- @author Pavel Makhov
-- @copyright 2019 Pavel Makhov
--------------------------------------------

local secrets = {
    -- Yandex.Translate API key - https://tech.yandex.com/translate/
    translate_widget_api_key = os.getenv('AWW_TRANSLATE_API_KEY') or 'API_KEY',

    -- OpenWeatherMap API key - https://openweathermap.org/appid
    weather_widget_api_key = os.getenv('AWW_WEATHER_API_KEY') or 'API_KEY',
    weather_widget_city = os.getenv('AWW_WEATHER_CITY') or 'Montreal,ca',
    weather_widget_units = os.getenv('AWW_WEATHER_UNITS') or 'metric' -- for celsius, or 'imperial' for fahrenheit
}

return secrets
