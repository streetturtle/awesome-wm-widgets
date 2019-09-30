-------------------------------------------------
-- Allows to store client specific settings in one place
--
-- @author Pavel Makhov
-- @copyright 2019 Pavel Makhov
--------------------------------------------

local secrets = {

    -- Yandex.Translate API key - https://tech.yandex.com/translate/
    translate_widget_api_key = os.getenv('AWW_TRANSLATE_API_KEY') or 'trnsl.1.1.20170708T010252Z.8b3fcacab3396ad1.88df3f48339672bce016a0e85a4db3aeb34dc7ae',
}

return secrets
