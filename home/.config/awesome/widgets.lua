local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local menubar = require("menubar")

local variables = require("variables")

-- {{{ Helper functions
local function client_menu_toggle_fn()
    local instance = nil

    return function ()
        if instance and instance.wibox.visible then
            instance:hide()
            instance = nil
        else
            instance = awful.menu.clients({ theme = { width = 250 } })
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
    { "quit", function() awesome.quit() end}
}

local main_menu = awful.menu({ items = { { "awesome", awesome_menu, beautiful.awesome_icon },
                                    { "open terminal", variables.terminal }
                                  }
                        })

-- local launcher = {}

-- Menubar configuration
menubar.utils.terminal = variables.terminal -- Set the terminal for applications that require it
-- }}}


-- {{{ Wibar
-- Create a textclock widget
local text_clock = wibox.widget.textclock()

local systray_widget = wibox.widget.systray()

-- Keyboard map indicator and switcher
local keyboard_layout = awful.widget.keyboardlayout()

-- Create a wibox for each screen and add it
local taglist_buttons = awful.util.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                )

local tasklist_buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
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
                                              end
                                          end),
                     awful.button({ }, 3, client_menu_toggle_fn()),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                          end))

return {
    main_menu=main_menu,
    text_clock=text_clock,
    systray_widget=systray_widget,
    keyboard_layout=keyboard_layout,
    taglist_buttons=taglist_buttons,
    tasklist_buttons=tasklist_buttons
}
