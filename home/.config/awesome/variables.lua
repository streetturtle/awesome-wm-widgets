local command = require("command")

local variables = {}

variables.config_dir = os.getenv("HOME") .. "/.config/awesome"

-- This is used later as the default terminal and editor to run.
variables.terminal = command.get_available_command({
        {command="gnome-terminal"},
        {command="x-terminal-emulator"},
        {command="terminator"},
        {command="konsole"},
        {command="xterm"},
    })
variables.browser = command.get_available_command({
        {command="firefox"},
        {command="firefox-bin"},
        {command="chromium"},
        {command="google-chrome"},
    })
variables.clipboard_manager = command.get_available_command({
        {command="clipit"},
        {command="klipper"},
        {command="qlipper", test="which qlipper"},
    })
variables.screen_configurator = "arandr"
variables.editor = os.getenv("EDITOR") or "vim"
variables.editor_cmd = variables.terminal .. " -e " .. variables.editor
variables.lgi_workaround = variables.config_dir .. "/lgi_workaround.sh"
variables.screenshot_tool = command.get_available_command({
    {command="gnome-screenshot", args="--interactive"},
    {command="spectacle"},
    })

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
variables.modkey = "Mod4"


return variables

