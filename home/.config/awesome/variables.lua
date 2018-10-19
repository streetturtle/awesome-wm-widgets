local command = require("command")

local variables = require("variables_base")

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
variables.screenshot_tool = command.get_available_command({
    {command="gnome-screenshot", args="--interactive"},
    {command="spectacle"},
    })

variables.editor_cmd = variables.terminal .. " -e " .. variables.editor

return variables

