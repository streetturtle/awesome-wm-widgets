-------------------------------------------------
-- Allows to store client specific settings in one place
--
-- @author Pavel Makhov
-- @copyright 2019 Pavel Makhov
--------------------------------------------

local function getenv_bool(var_name, default_val)
    val = os.getenv(var_name)
    if val ~= nil then
        return val:lower() == 'true'
    else
        return default_val
    end
end

local secrets = {
    -- See volume-widget/README.md
    volume_audio_controller = os.getenv('AWW_VOLUME_CONTROLLER') or 'pulse', -- 'pulse' or 'alsa_only'

    -- Yandex.Translate API key - https://tech.yandex.com/translate/
    translate_widget_api_key = os.getenv('AWW_TRANSLATE_API_KEY') or 'API_KEY',

    -- OpenWeatherMap API key - https://openweathermap.org/appid
    weather_widget_api_key = os.getenv('AWW_WEATHER_API_KEY') or 'API_KEY',
    weather_widget_city = os.getenv('AWW_WEATHER_CITY') or 'Montreal,ca',
    weather_widget_units = os.getenv('AWW_WEATHER_UNITS') or 'metric', -- for celsius, or 'imperial' for fahrenheit
    weather_both_temp_units_widget = getenv_bool('AWW_WEATHER_BOTH_UNITS_WIDGET', false), -- on widget, if true shows "22 C (72 F)", instead of only "22 C"
    weather_both_temp_units_popup = getenv_bool('AWW_WEATHER_BOTH_UNITS_POPUP', true) -- in the popup, if true shows "22.3 C (72.2 F)" instead of only "22.3 C"
}

return secrets
