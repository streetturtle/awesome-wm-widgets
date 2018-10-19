variables = {}

variables.config_dir = os.getenv("HOME") .. "/.config/awesome"
variables.screen_configurator = "arandr"
variables.editor = os.getenv("EDITOR") or "vim"

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
variables.modkey = "Mod4"

return variables
