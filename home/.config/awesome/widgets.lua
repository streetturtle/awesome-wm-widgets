local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup").widget
local variables = require("variables")
local power = require("power")
local naughty = require("naughty")
local debug_util = require("debug_util")

local function property_toggler_menu_item(element, key, turn_on, turn_off)
    if element[key] then
        return {turn_off, function() element[key] = false end }
    else
        return {turn_on, function() element[key] = true end }
    end
end

-- {{{ Helper functions
local function client_menu_toggle_fn()
    local instance = nil

    return function (c)
        if instance and instance.wibox.visible then
            instance:hide()
            instance = nil
        else
            instance = awful.menu({
                    property_toggler_menu_item(c, "minimized",
                            "Minimize", "Restore"),
                    property_toggler_menu_item(c, "maximized",
                            "Maximize", "Unmaximize"),
                    {"Close", function() c:kill() end},
            })
            instance:show()
        end
    end
end

-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
local awesome_menu = {
    { "hotkeys", function() return false, hotkeys_popup.show_help end},
    { "manual", variables.terminal .. " -e man awesome" },
    { "edit config", variables.editor_cmd .. " " .. awesome.conffile },
    { "restart", awesome.restart },
    { "quit", power.quit}
}

local power_menu = {
    { "reboot", power.reboot},
    { "suspend", power.suspend},
    { "hibernate", power.hibernate},
    { "power off", power.poweroff},
}

local main_menu = awful.menu({
    items = {
        {"awesome", awesome_menu, beautiful.awesome_icon},
        {"open terminal", variables.terminal},
        {"power", power_menu},
    }})

-- local launcher = {}

-- Menubar configuration
menubar.utils.terminal = variables.terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Wibar
-- Create a textclock widget
local text_clock = wibox.widget.textclock()

local systray_widget = wibox.widget.systray()

-- Create a wibox for each screen and add it
local taglist_buttons = awful.util.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ variables.modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ variables.modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                )

local tasklist_buttons = awful.util.table.join(
                     awful.button({ }, 1,
                             function (c)
                                 -- Without this, the following
                                 -- :isvisible() makes no sense
                                 c.minimized = false
                                 if not c:isvisible() and c.first_tag then
                                     c.first_tag:view_only()
                                 end
                                 -- This will also un-minimize
                                 -- the client, if needed
                                 client.focus = c
                                 c:raise()
                             end),
                     awful.button({ }, 2, function(c) c:kill() end),
                     awful.button({ }, 3, client_menu_toggle_fn()),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                          end))

-- Keyboard map indicator and changer
local keyboard_layout_switcher = {}

local function set_keyboard_layout_text(layout)
    keyboard_layout_switcher.widget:set_text(" 🖮 " .. layout[3] .. " ")
end

keyboard_layout_switcher.cmd = "setxkbmap"
keyboard_layout_switcher.layout = {
        { "hu", "102_qwertz_dot_nodead" , "HU" },
        { "us", "" , "EN" } }
keyboard_layout_switcher.current = 1  -- us is our default layout
keyboard_layout_switcher.widget = wibox.widget.textbox()
set_keyboard_layout_text(keyboard_layout_switcher.layout[
        keyboard_layout_switcher.current])
keyboard_layout_switcher.widget:set_text(" foo "
        .. keyboard_layout_switcher.layout[keyboard_layout_switcher.current][3]
        .. " barf ")
keyboard_layout_switcher.switch = function ()
    keyboard_layout_switcher.current = keyboard_layout_switcher.current
            % #(keyboard_layout_switcher.layout) + 1
    keyboard_layout_switcher.update()
end
keyboard_layout_switcher.update = function()
    local t = keyboard_layout_switcher.layout[keyboard_layout_switcher.current]
    set_keyboard_layout_text(t)
    os.execute( keyboard_layout_switcher.cmd .. " " .. t[1] .. " " .. t[2] )
end
keyboard_layout_switcher.widget:connect_signal("button::press",
        keyboard_layout_switcher.switch)

keyboard_layout_switcher.update()

-- }}}

return {
    main_menu=main_menu,
    text_clock=text_clock,
    systray_widget=systray_widget,
    taglist_buttons=taglist_buttons,
    tasklist_buttons=tasklist_buttons,
    keyboard_layout_switcher = keyboard_layout_switcher
}
