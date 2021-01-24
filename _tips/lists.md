---
layout: page
---

# Lists

This type of UI element is also called menu (for example in GTK).
As an example let's create a bookmarks widget - a widget will show a static list of sites. If item in the list is clicked - the site will be opened in the browser. You can find the created widget [here](https://github.com/streetturtle/awesome-wm-tutorials/tree/master/bookmark-widget)

## Prerequisite

Create a bookmark-widget.lua file under ~/.config/awesome/tutorials folder. Then include it in your rc.lua and add widget to the wibox:

```lua
local bookmark_widget = require("tutorials.bookmark-widget.bookmark-widget")
...
s.mytasklist, -- Middle widget
{ -- Right widgets
    ...
    bookmark_widget
```

To have a list popup, first we need to have an "anchor" widget, clicking on which should toggle the visibility of the list, so let's create it, it will be an icon:

```lua
local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")

local HOME = os.getenv('HOME')
local ICON_DIR = HOME .. '/home-dev/awesome-wm-widget-tutorial/awesome-wm-widgets/bookmark-widget/icons/'

local bookmark_widget = wibox.widget {
    {
        image = ICON_DIR .. 'bookmark.svg',
        resize = true,
        widget = wibox.widget.imagebox,
    },
    margins = 4,
    widget = wibox.container.margin
}

-- code mentioned below goes here

return bookmark_widget
```

Now restart awesome and boom! - you have a widget:

![1]({{ "/assets/img/tips/lists/1.png" | relative_url }}){:.center-image}

## Widget structure

We are going to use an [awful.popup](https://awesomewm.org/doc/api/classes/awful.popup.html) as it's quite easy to show/hide it and also to place it on the screen. On the popup we'll add text and image widgets, arranged in a vertical list using [layout.fixed](https://awesomewm.org/doc/api/classes/wibox.layout.fixed.html) layout plus [container.margin](https://awesomewm.org/doc/api/classes/wibox.container.margin.html) and [container.background](https://awesomewm.org/doc/api/classes/wibox.container.background.html) to make it look nice and to change the background color on mouse hover:

![widget structure]({{ "/assets/img/tips/lists/bookmark_structure.png" | relative_url }}){:.center-image}


## Let's start

Each item in the list will have three components: an icon, a text and an url to open when the item is clicked. Let's represent it in lua:

```lua
local menu_items = {
    { name = 'Reddit', icon_name = 'reddit.svg', url = 'https://www.reddit.com/' },
    { name = 'StackOverflow', icon_name = 'stackoverflow.svg', url = 'http://github.com/' },
    { name = 'GitHub', icon_name = 'github.svg', url = 'https://stackoverflow.com/' },
}
```

Then let's define a popup and rows (which will hold the vertical layout), to which we will add items later on:

```lua
local popup = awful.popup {
    ontop = true,
    visible = false, -- should be hidden when created
    shape = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, 4)
    end,
    border_width = 1,
    border_color = beautiful.bg_focus,
    maximum_width = 400,
    offset = { y = 5 },
    widget = {}
}
local rows = { layout = wibox.layout.fixed.vertical }
```

Now we'll just traverse over the `menu_items`, create a row (let's start with a simple textbox widget), add it to rows and then add rows to the popup:

```lua
for _, item in ipairs(menu_items) do

    local row = wibox.widget {
        text = item.name,
        widget = wibox.widget.textbox
    }
    table.insert(rows, row)
end
popup:setup(rows)
```

The last thing left is to toggle popup visibility on mouse click on the `bookmark_widget`:

```lua
bookmark_widget:buttons(
    awful.util.table.join(
        awful.button({}, 1, function()
            if popup.visible then
                popup.visible = not popup.visible
            else
                 popup:move_next_to(mouse.current_widget_geometry)
            end
    end))
)
```

Restart awesome and click on the widget:

![1]({{ "/assets/img/tips/lists/1_1.png" | relative_url }}){:.center-image}

## Make it pretty

To add an icon let's wrap textbox in a fixed.horizontal layout and add an imagebox with an icon in front of it. Note that it's important to set the maximum height and width of the image, otherwise it will take up all available space:

<div class="row">
  <div class="col s6">
```lua
local row = wibox.widget {
    {
        image = ICON_DIR .. item.icon_name,
        forced_width = 16,
        forced_height = 16,
        widget = wibox.widget.imagebox
    },
    {
        text = item.name,
        widget = wibox.widget.textbox
    },
    layout = wibox.layout.fixed.horizontal
}
```
  </div>
  <div class="col s6">
![1]({{ "/assets/img/tips/lists/2.png" | relative_url }}){:.center-image}
  </div>
</div>


Looks ok, but icon and text are too close to each other. One way to fix it is to use a [spacing](https://awesomewm.org/doc/api/classes/wibox.layout.fixed.html#wibox.layout.fixed.spacing) property of the fixed layout, which sets the distance between widgets:

<div class="row">
  <div class="col s6">
```lua
local row = wibox.widget {
    {
        image = ICON_DIR .. item.icon_name,
        forced_width = 16,
        forced_height = 16,
        widget = wibox.widget.imagebox
    },
    {
        text = item.name,
        widget = wibox.widget.textbox
    },
    spacing = 12, -- <--
    layout = wibox.layout.fixed.horizontal
}
```
  </div>
  <div class="col s6">
![1]({{ "/assets/img/tips/lists/3.png" | relative_url }}){:.center-image}
  </div>
</div>

Now let's add margins around each item:

<div class="row">
  <div class="col s6">
```lua
local row = wibox.widget {
    {
        {
            image = ICON_DIR .. item.icon_name,
            forced_width = 16,
            forced_height = 16,
            widget = wibox.widget.imagebox
        },
        {
            text = item.name,
            widget = wibox.widget.textbox
        },
        spacing = 12,
        layout = wibox.layout.fixed.horizontal
    },
    margins = 8,
    widget = wibox.container.margin
}
```
  </div>
  <div class="col s6">
![1]({{ "/assets/img/tips/lists/4.png" | relative_url }}){:.center-image}
  </div>
</div>


One more step is to wrap margins in a background. Visually it won't change anything (unless you want to change the default color, which is `bg_normal` from your theme), but it will be useful later, when we will add mouse hover effect to the menu item

<div class="row">
  <div class="col s6">
```lua
local row = wibox.widget {
    {
        {
            {
                image = ICON_DIR .. item.icon_name,
                forced_width = 16,
                forced_height = 16,
                widget = wibox.widget.imagebox
            },
            {
                text = item.name,
                widget = wibox.widget.textbox
            },
            spacing = 12,
            layout = wibox.layout.fixed.horizontal
        },
        margins = 8,
        widget = wibox.container.margin
    },
    bg = beautiful.bg_normal,
    widget = wibox.container.background
}
```
  </div>
  <div class="col s6">
![1]({{ "/assets/img/tips/lists/4.png" | relative_url }}){:.center-image}
  </div>
</div>

Looks good now! Let's add some interactivity, like changing background on mouse hover, note that `c` in the callback function's parameter is a `row`, defined above, which is a background widget, so we can set the background color with `set_bg` method:

<div class="row">
  <div class="col s6">
```lua
row:connect_signal("mouse::enter", function(c) 
    c:set_bg(beautiful.bg_focus) 
end)
row:connect_signal("mouse::leave", function(c) 
    c:set_bg(beautiful.bg_normal) 
end)
```
  </div>
  <div class="col s6">
![1]({{ "/assets/img/tips/lists/5.gif" | relative_url }}){:.center-image}
  </div>
</div>

Let's also change a cursor:

<div class="row">
  <div class="col s6">
```lua
local old_cursor, old_wibox
row:connect_signal("mouse::enter", function()
    local wb = mouse.current_wibox
    old_cursor, old_wibox = wb.cursor, wb
    wb.cursor = "hand1"
end)
row:connect_signal("mouse::leave", function()
    if old_wibox then
        old_wibox.cursor = old_cursor
        old_wibox = nil
    end
end)
```
  </div>
  <div class="col s6">
![1]({{ "/assets/img/tips/lists/6.gif" | relative_url }}){:.center-image}
  </div>
</div>

## Make it work

The last bit is to open the link, when mouse is clicked. We'll use the [buttons](https://awesomewm.org/doc/api/classes/wibox.container.background.html#wibox.container.background:buttons) method which accepts a table of buttons. First parameter is a table with modifiers (we use none), second is a button number (1 is a left mouse button), third parameter is a callback function which is called on press action. When mouse button is clicked we want to hide the popup and open the link in the default browser. [xdg-open](https://linux.die.net/man/1/xdg-open) is used exactly for that:

```lua
row:buttons(
    awful.util.table.join(
        awful.button({}, 1, function()
            popup.visible = not popup.visible
            awful.spawn.with_shell('xdg-open ' .. item.url)
        end)
    )
)
```

## Future improvements

The menu or list widget, created above, looks pretty standard, as it has icon and text. However, playing with different layouts you can add more items to it, for example you may follow material design [guidance](https://material.io/components/lists#types) and create lists with many components, like three-lines lists with visuals and controls. As an example here is a list from [gitlab](https://github.com/streetturtle/awesome-wm-widgets/tree/master/gitlab-widget) widget:

![](https://github.com/streetturtle/awesome-wm-widgets/raw/master/gitlab-widget/screenshot.png)

And another one from [github-activity-widget](https://github.com/streetturtle/awesome-wm-widgets/tree/master/github-activity-widget):

![1]({{ "/assets/img/tips/lists/github.png" | relative_url }}){:.center-image}

And one more from [docker](https://github.com/streetturtle/awesome-wm-widgets/tree/master/docker-widget) widget:

![1]({{ "/assets/img/tips/lists/docker.png" | relative_url }}){:.center-image}

Widget described above can be found [here](https://github.com/streetturtle/awesome-wm-tutorials/tree/master/bookmark-widget)
