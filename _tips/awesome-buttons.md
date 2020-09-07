---
layout: page
---

# Awesome Buttons

Here I want to share a way of creating fancy looking interactive buttons:

![awesome-buttons]({{ "/assets/img/tips/awesome-buttons.png" | relative_url }}){:.center-image}


## Prerequisite

Add the section below to your rc.lua, which will be used as a canvas:

```lua
local buttons_example = wibox {
    visible = true,
    bg = '#2E3440',
    ontop = true,
    height = 1E00,
    width = 200,
    shape = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, 3)
    end
}

local button = {} -- <- code examples go here

buttons_example:setup {
    button,
    valigh = 'center',
    layout = wibox.container.place
}

awful.placement.top(buttons_example, { margins = {top = 40}, parent = awful.screen.focused()})
```

## Button

Buttons usually consist of text, icon or both. Let's start with a simple text button:

<div class="row">
  <div class="col s6">
```lua
local button = wibox.widget{
    text = "I'm a button!",
    widget = wibox.widget.textbox
}
```
  </div>
  <div class="col s6">
![awesome-buttons]({{ "/assets/img/tips/awesome-buttons/ab-1.png" | relative_url }}){:.center-image}
  </div>
</div>

For the image button replace the textbox by the imagebox. For the icon and text button, combine both of them in the fixed horizontal layout:

```lua
{
    {
        {
            image = icon,
            resize = true,
            forced_height = 20,
            widget = wibox.widget.imagebox
        },
        margins = 4,
        widget = wibox.container.margin
    },
    {
        {
            text = 'Click me!',
            widget = wibox.widget.textbox
        },
        top = 4, bottom = 4, right = 8,
        widget = wibox.container.margin
    },
    layout = wibox.layout.align.horizontal
}
```

Next step is to add some margins and a background. For background we'll use `wibox.container.background`, it allows to set the background itself (`bg = '#4C566A'`). By using alpha channel it's possible to make a transparent background (`bg = '#00000000'`) which will be useful in the next step when adding hover effect. Apart from a background, it also sets shape and borders, which allows to create 'outline' buttons (`shape_border_width = 1, shape_border_color = '#4C566A'`). These three types are shown in the example below:

<div class="row">
  <div class="col s6">
```lua
local button = wibox.widget{
    {
        {
            text = "I'm a button!",
            widget = wibox.widget.textbox
        },
        top = 4, bottom = 4, left = 8, right = 8,
        widget = wibox.container.margin
    },
    bg = '#4C566A', -- basic
    bg = '#00000000', --tranparent
    shape_border_width = 1, shape_border_color = '#4C566A', -- outline
    shape = function(cr, width, height) 
        gears.shape.rounded_rect(cr, width, height, 4) 
    end,
    widget = wibox.container.background
}
```
  </div>
  <div class="col s6">
![awesome-buttons]({{ "/assets/img/tips/awesome-buttons/ab-2.png" | relative_url }}){:.center-image}
![awesome-buttons]({{ "/assets/img/tips/awesome-buttons/ab-3.png" | relative_url }}){:.center-image}
![awesome-buttons]({{ "/assets/img/tips/awesome-buttons/ab-4.png" | relative_url }}){:.center-image}
  </div>
</div>

## Hover effects

Now the button looks like a button, but doesn't behave like one. First thing is to change colors when mouse cursor hovers over the button. To do it we can leverage the signals: `mouse::enter` and `mouse::leave`. When using signals, we have access the to widget, so it's pretty simple to change the color. Below I use alpha channel to darken the color of the button a bit, for all three types of button discussed above it works well:

<div class="row">
  <div class="col s8">
```lua
button_basic:connect_signal("mouse::enter", function(c) c:set_bg("#00000066") end)
button_basic:connect_signal("mouse::leave", function(c) c:set_bg('#4C566A') end)
button_tranparent:connect_signal("mouse::enter", function(c) c:set_bg("#00000066") end)
button_tranparent:connect_signal("mouse::leave", function(c) c:set_bg('#00000000') end)
button_outline:connect_signal("mouse::enter", function(c) c:set_bg("#00000066") end)
button_outline:connect_signal("mouse::leave", function(c) c:set_bg('#00000000') end)
```
  </div>
  <div class="col s4">
![awesome-buttons]({{ "/assets/img/tips/awesome-buttons/ab-5.gif" | relative_url }}){:.center-image}
  </div>
</div>

Note that you need to set the initial color of the button for the `mouse::leave` signal. 

Second thing is to change the cursor:

<div class="row">
  <div class="col s8">
```lua
local old_cursor, old_wibox
button_basic:connect_signal("mouse::enter", function(c)
    c:set_bg("#00000066")
    local wb = mouse.current_wibox
    old_cursor, old_wibox = wb.cursor, wb
    wb.cursor = "hand1" 
end)
button_basic:connect_signal("mouse::leave", function(c)
    c:set_bg('#4C566A')
    if old_wibox then
        old_wibox.cursor = old_cursor
        old_wibox = nil
    end
end)
```
  </div>
  <div class="col s4">
![awesome-buttons]({{ "/assets/img/tips/awesome-buttons/ab-6.gif" | relative_url }}){:.center-image}
  </div>
</div>

## Button click effects

Another effect is changing the color of the button when the button is pressed/released:

<div class="row">
  <div class="col s8">
```lua
button_basic:connect_signal("button::press", function(c) c:set_bg("#000000") end)
button_basic:connect_signal("button::release", function(c) c:set_bg('#00000066') end)
```
  </div>
  <div class="col s4">
![awesome-buttons]({{ "/assets/img/tips/awesome-buttons/ab-7.gif" | relative_url }}){:.center-image}
  </div>
</div>

## Onclick action

To perform some action when the button is clicked you need to handle press/release signal. The important part here is to properly handle the button which was used, otherwise any click will trigger the function execution:

```lua
button_basic:connect_signal("button::press", function(c, _, _, button) 
    if button == 1 then  naughty.notify{text = 'Left click'} 
    elseif button == 2 then naughty.notify{text = 'Wheel click'} 
    elseif button == 3 then naughty.notify{text = 'Right click'} 
    end
end)
```

## Summary

As you can see it is pretty easy to create interactive nice-looking buttons. But if you use multiple buttons in your widget, you may have quite a lot of boilerplate code. To solve this issue I created an [awesome-buttons](https://github.com/streetturtle/awesome-buttons) library, which simplifies this process:

```lua
awesomebuttons.with_text{ type = 'flat', text = 'Ola', color = '#f8f', text_size = 12 },
awesomebuttons.with_icon{ type = 'outline', icon = 'zoom-in', color = '#f8f', shape = 'rounded_rect' },
awesomebuttons.with_icon_and_text{ icon = 'check-circle', text = 'With Icon!', color = '#f48' },
```

Please refer to the repo's README for more details. It is still in progress. 
