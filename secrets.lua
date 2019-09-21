-------------------------------------------------
-- Allows to store client specific settings in one place
--
-- @author Pavel Makhov
-- @copyright 2019 Pavel Makhov
--------------------------------------------

local secrets = {

    -- Yandex.Translate API key - https://tech.yandex.com/translate/
    translate_widget_api_key = os.getenv('AWW_TRANSLATE_API_KEY') or '<your_key>',

    -- OpenWeatherMap API key - https://openweathermap.org/appid
    weather_widget_api_key = os.getenv('AWW_WEATHER_API_KEY') or '<your_key>',
}

return secrets
