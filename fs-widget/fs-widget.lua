local awful = require("awful")
local watch = require("awful.widget.watch")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gears = require("gears")

local storage_bar_widget = {}

local function worker(args)
    local args = args or {}
    local mounts = args.mounts or {'/'}

    storage_bar_widget = wibox.widget {
        max_value = 100,
        forced_height = 20,
        forced_width = 35,
        paddings = 1,
        margins = 4,
        border_width = 0.5,
        border_color = beautiful.fg_normal,
        background_color = beautiful.bg_normal,
        bar_border_width = 1,
        bar_border_color = beautiful.bg_focus,
        color = "linear:150,0:0,0:0,"
          .. beautiful.fg_normal
          .. ":0.3," .. beautiful.bg_urgent .. ":0.6,"
          .. beautiful.fg_normal,
        widget = wibox.widget.progressbar,
    }

    local disk_rows = {
        { widget = wibox.widget.textbox },
        spacing = 4,
        layout = wibox.layout.fixed.vertical,
    }

    local disk_header = {
      {
        markup = '<b>Mount</b>',
        forced_width = 150,
        align  = 'left',
        widget = wibox.widget.textbox,
      },
      {
        markup = '<b>Used</b>',
        align  = 'left',
        widget = wibox.widget.textbox,
      },
      layout = wibox.layout.align.horizontal
    }

    local popup = awful.popup{
        ontop         = true,
        visible       = false,
        shape         = gears.shape.rounded_rect,
        border_width  = 1,
        border_color  = beautiful.bg_normal,
        bg            = beautiful.bg_focus,
        maximum_width = 400,
        offset        = { y = 5 },
        widget        = {}
    }
    popup:connect_signal("mouse::enter", function(c) is_update = false end)
    popup:connect_signal("mouse::leave", function(c) is_update = true end)

    storage_bar_widget:buttons(
      awful.util.table.join(
        awful.button({}, 1, function()
          if popup.visible then
            popup.visible = not popup.visible
          else
            popup:move_next_to(mouse.current_widget_geometry)
          end
        end)
        )
      )

    local disk_widget = wibox.container.margin(storage_bar_widget, 0, 0, 0, 0)

    local disks = {}
    watch([[bash -c "df | tail -n +2"]], 60,
        function(widget, stdout)
          for line in stdout:gmatch("[^\r\n$]+") do
            local filesystem, size, used, avail, perc, mount =
              line:match('([%p%w]+)%s+([%d%w]+)%s+([%d%w]+)%s+([%d%w]+)%s+([%d]+)%%%s+([%p%w]+)')

            disks[mount]            = {}
            disks[mount].filesystem = filesystem
            disks[mount].size       = size
            disks[mount].used       = used
            disks[mount].avail      = avail
            disks[mount].perc       = perc
            disks[mount].mount      = mount

            if disks[mount].mount == mounts[1] then
              widget.value = tonumber(disks[mount].perc)
            end
          end

          for k,v in ipairs(mounts) do

            local row = wibox.widget{
              {
                  text = disks[v].mount,
                  forced_width = 150,
                  widget = wibox.widget.textbox
              },
              {
                  max_value = 100,
                  value = tonumber(disks[v].perc),
                  forced_height = 20,
                  paddings = 1,
                  margins = 4,
                  border_width = 1,
                  border_color = beautiful.bg_focus,
                  background_color = beautiful.bg_normal,
                  bar_border_width = 1,
                  bar_border_color = beautiful.bg_focus,
                  color = "linear:150,0:0,0:0,"
                    .. beautiful.fg_normal
                    .. ":0.3," .. beautiful.bg_urgent .. ":0.6,"
                    .. beautiful.fg_normal,
                  widget = wibox.widget.progressbar,

              },
              {
                  text = math.floor(disks[v].used/1024/1024)
                    .. '/'
                    .. math.floor(disks[v].size/1024/1024) .. 'GB('
                    .. math.floor(disks[v].perc) .. '%)',
                  widget = wibox.widget.textbox
              },
              layout = wibox.layout.align.horizontal
            }

            disk_rows[k] = row
          end
          popup:setup {
              {
                  disk_header,
                  disk_rows,
                  layout = wibox.layout.fixed.vertical,
              },
              margins = 8,
              widget = wibox.container.margin
          }
        end,
        storage_bar_widget
    )

    return disk_widget
end

return setmetatable(storage_bar_widget, { __call = function(_, ...)
    return worker(...)
end })
