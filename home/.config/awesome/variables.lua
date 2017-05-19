local util = require("util")

local config_dir = os.getenv("HOME") .. "/.config/awesome"

-- This is used later as the default terminal and editor to run.
local terminal = util.get_available_command({
        {command="gnome-terminal"},
        {command="konsole"},
        {command="x-terminal-emulator"},
        {command="xterm"}})
local editor = os.getenv("EDITOR") or "vim"
local editor_cmd = terminal .. " -e " .. editor
local screenshot_tool = util.get_available_command({
    {command="gnome-screenshot", args="--interactive"}})

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
local modkey = "Mod4"


return {
    config_dir=config_dir,
    terminal=terminal,
    editor=editor,
    editor_cmd=editor_cmd,
    screenshot_tool=screenshot_tool,
    modkey=modkey,
}

