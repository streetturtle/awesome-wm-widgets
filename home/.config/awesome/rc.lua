local debug_util = require("debug_util")

debug_util.log("-----------------------------------")
debug_util.log("Awesome starting up")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")

local hotkeys_popup = require("awful.hotkeys_popup").widget
local xrandr = require("xrandr")
local multimonitor = require("multimonitor")
local variables = require("variables")
local util = require("util")
local widgets = require("widgets")
local cyclefocus = require('cyclefocus')
local input = require('input')
local xscreensaver = require('xscreensaver')

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({
                preset = naughty.config.presets.critical,
                title = "Oops, an error happened!",
                text = tostring(err),
                destroy = function(reason)
                    if reason == naughty.notificationClosedReason.
                            dismissedByUser then
                        local stream = io.popen("xsel --input --clipboard", "w")
                        stream:write(tostring(err))
                        stream:close()
                    end
                end})
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions

-- Themes define colours, icons, font and wallpapers.
local theme = dofile(awful.util.get_themes_dir() .. "default/theme.lua")

local wallpaper_file = variables.config_dir .. "/wallpaper"
if gears.filesystem.file_readable(wallpaper_file) then
    theme.wallpaper = wallpaper_file
end
theme.titlebar_bg_focus = "#007EE6"

local modkey = variables.modkey

beautiful.init(theme)

local APW = require("apw/widget")

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier,
    awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}
-- }}}

-- {{{ Menu
local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, false)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

local launcher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = widgets.main_menu })

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag({"1", "2"}, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, widgets.taglist_buttons)

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, widgets.tasklist_buttons)

    -- s.mytasklist:connect_signal("mouse::enter",
    --         function(c)
    --             c:raise()
    --         end)
    -- s.mytasklist:connect_signal("mouse::leave",
    --         function(_)
    --             client.focus:raise()
    --         end)
    -- Create the wibox
    s.mywibox = awful.wibar({ position = "bottom", screen = s })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            launcher,
            s.mytaglist,
            s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            widgets.keyboard_layout_switcher.widget,
            APW,
            widgets.systray_widget,
            widgets.text_clock,
            s.mylayoutbox,
        },
    }
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
local globalkeys = awful.util.table.join(
    awful.key({ "Mod4",           }, "s",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),
    -- awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
    --           {description = "view previous", group = "tag"}),
    -- awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
    --           {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),

    awful.key({ modkey, }, "j",
        function ()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),
    awful.key({ modkey, }, "k",
        function ()
            awful.client.focus.byidx(1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end,
              {description = "show main menu", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "s", multimonitor.show_screens,
              {description = "show screens", group = "screen"}),
    awful.key({ modkey, }, "F1",
            function()
                debug_util.log("Detecting screen configuration")
                multimonitor.detect_screens()
            end,
              {description = "show screens", group = "screen"}),
    awful.key({ modkey, }, "F2", multimonitor.print_debug_info,
              {description = "print debug info", group = "screen"}),
    awful.key({ modkey, }, "F3",
            function()
                local text = ""
                for _, c in pairs(client.get()) do
                    text = text .. c.window .. " " .. c.class .. " " .. c.name
                            .. " Screen " .. c.screen.index .. "\n"
                end
                naughty.notify({text=text, timeout=30})
                awful.spawn.easy_async("xlsclients -a",
                    function(stdout, stderr, _, _)
                        naughty.notify({
                                text=stdout .. "\n" .. stderr,
                                timeout=30})
                    end)
            end, {description = "print debug info", group = "screen"}),
    awful.key({modkey, "Shift"}, "t",
            function()
                multimonitor.set_system_tray_position()
            end,
            {description = "Put system tray to this screen", group="screen"}),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey, "Control" }, "k",
            function ()
                awful.screen.focus(awful.screen.focused()
                        :get_next_in_direction("right"))
            end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey, "Control" }, "j",
            function ()
                awful.screen.focus(awful.screen.focused()
                        :get_next_in_direction("left"))
            end,
              {description = "focus the previous screen", group = "screen"}),
    awful.key({ modkey, "Shift"   }, "x",
          function()
            debug_util.log("Creating new screen configuration")
             xrandr.xrandr(multimonitor.clear_layout,
                     multimonitor.detect_screens)
          end,
              {description = "Show xrandr menu", group = "screen"}),
    awful.key({ modkey, }, "l",
          function()
              xscreensaver.lock()
          end,
              {description = "Show xrandr menu", group = "screen"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),

-- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(variables.terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({}, "Print",
            function ()
                awful.spawn.with_shell(variables.screenshot_tool)
            end,
            {description = "Take screenshot", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"}),

    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
              {description = "select next", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
              {description = "select previous", group = "layout"}),

    awful.key({ modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Focus restored client
                  if c then
                      client.focus = c
                      c:raise()
                  end
              end,
              {description = "restore minimized", group = "client"}),

    --- Volume
    awful.key({ }, "XF86AudioRaiseVolume",  APW.Up,
            {description="Volume Up", group="volume"}),
    awful.key({ }, "XF86AudioLowerVolume",  APW.Down,
            {description="Volume Down", group="volume"}),
    awful.key({ }, "XF86AudioMute",         APW.ToggleMute,
            {description="Toggle Mute", group="volume"}),

    -- Prompt
    awful.key({ modkey },            "r",     function () awful.screen.focused().mypromptbox:run() end,
              {description = "run prompt", group = "launcher"}),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run {
                    prompt       = "Run Lua code: ",
                    textbox      = awful.screen.focused().mypromptbox.widget,
                    exe_callback = awful.util.eval,
                    history_path = awful.util.get_cache_dir() .. "/history_eval"
                  }
              end,
              {description = "lua execute prompt", group = "awesome"}),
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end,
              {description = "show the menubar", group = "launcher"}),
    awful.key({modkey, "Shift"}, "l", widgets.keyboard_layout_switcher.switch,
            {description="switch keyboard layout", group="input"}),
    awful.key({}, "XF86TouchpadToggle",
            function()
                input.toggle_device(input.touchpad)
            end,
            {description="toggle touchpad", group="input"})
)

local clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ "Mod1"   }, "F4",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"}),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),
    awful.key({ modkey,           }, "Right",
            function (c)
                c:move_to_screen(c.screen:get_next_in_direction("right"))
            end,
            {description = "move to previous screen", group = "client"}),
    awful.key({ modkey,           }, "Left",
            function (c)
                c:move_to_screen(c.screen:get_next_in_direction("left"))
            end,
            {description = "move to next screen", group = "client"}),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"}),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end ,
        {description = "minimize", group = "client"}),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "maximize", group = "client"}),
    awful.key({ "Mod1",         }, "Tab", function(c)
        cyclefocus.cycle(1, {
                modifier="Alt_L",
                cycle_filters={cyclefocus.filters.same_screen},
                initiating_client=c
            })
    end),
    awful.key({ "Mod1", "Shift" }, "Tab", function(c)
        cyclefocus.cycle(-1, {
                modifier="Alt_L",
                cycle_filters={cyclefocus.filters.same_screen},
                initiating_client=c
            })
    end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 2 do
    globalkeys = awful.util.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

local clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     raise = true,
                     focus = false,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen
     }
    },

    -- Floating clients.
    { rule_any = {
        instance = {
          "DTA",  -- Firefox addon DownThemAll.
          "copyq",  -- Includes session name in class.
        },
        class = {
          "Arandr",
          "Gpick",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Sxiv",
          "Wpa_gui",
          "pinentry",
          "veromix",
          "xtightvncviewer"},

        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }},

    -- Add titlebars to normal clients and dialogs
    { rule_any = {type = { "normal", "dialog" }
      }, properties = { titlebars_enabled = true }
    },

    -- Set Firefox to always map on the tag named "2" on screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { screen = 1, tag = "2" } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = awful.util.table.join(
        awful.button({ }, 1, function()
            client.focus = c
            c:raise()
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            client.focus = c
            c:raise()
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c) : setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c) then
        client.focus = c
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

client.connect_signal("unfocus",
        function(c)
            if not c.minimized then
                return
            end
            gears.timer.start_new(0.1,
                    function()
                        local target = mouse.current_client
                        if target == c then
                            return true
                        end
                        if target then
                            client.focus = target
                        end
                        return false
                    end)
        end)

screen.connect_signal("list",
        function()
            debug_util.log("Screen configuration changed")
            multimonitor.detect_screens()
        end)

client.connect_signal("manage",
        function(c)
            multimonitor.manage_client(c)
        end)
client.connect_signal("property::position",
        function(c)
            multimonitor.manage_client(c)
        end)
client.connect_signal("unmanage",
        function(c)
            multimonitor.unmanage_client(c)
        end)

awesome.connect_signal("startup", multimonitor.detect_screens)

-- }}}

local APWTimer = timer({ timeout = 0.5 }) -- set update interval in s
APWTimer:connect_signal("timeout", APW.Update)
APWTimer:start()

util.start_if_not_running("clipit", "")
util.start_if_not_running("nm-applet", "")
util.start_if_not_running("xbindkeys", "")

local local_rc_file = variables.config_dir .. "/rc.local.lua"
if gears.filesystem.file_readable(local_rc_file) then
    dofile(local_rc_file)
end

debug_util.log("Initialization finished")
