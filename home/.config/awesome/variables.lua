local util = require("util")

local config_dir = os.getenv("HOME") .. "/.config/awesome"

-- This is used later as the default terminal and editor to run.
local terminal = util.get_available_command({
        "gnome-terminal", "konsole", "x-terminal-emulator", "xterm"})
local editor = os.getenv("EDITOR") or "vim"
local editor_cmd = terminal .. " -e " .. editor

return {
    config_dir=config_dir,
    terminal=terminal,
    editor=editor,
    editor_cmd=editor_cmd
}

