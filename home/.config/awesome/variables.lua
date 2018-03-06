local command = require("command")

local variables = {}

variables.config_dir = os.getenv("HOME") .. "/.config/awesome"

-- This is used later as the default terminal and editor to run.
variables.terminal = command.get_available_command({
        {command="gnome-terminal"},
        {command="konsole"},
        {command="x-terminal-emulator"},
        {command="xterm"}})
variables.browser = command.get_available_command({
        {command="firefox"},
        {command="chromium"},
        {command="google-chrome"}})
variables.screen_configurator = "arandr"
variables.editor = os.getenv("EDITOR") or "vim"
variables.editor_cmd = variables.terminal .. " -e " .. variables.editor
variables.screenshot_tool = command.get_available_command({
    {command="gnome-screenshot", args="--interactive"}})

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
variables.modkey = "Mod4"


return variables

