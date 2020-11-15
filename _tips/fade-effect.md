---
layout: page
---

# Fade effect on a widget

Here is a nice fade-out / fade-in effect which can be applied on text/image widgets (or any other widget which supports opacity). It can be used either on click or on hover actions:

![fade]({{ "/assets/img/snippets/fade.gif" | relative_url }}){:.center-image}

>Fade effect on a widget
{:.filename}
```lua
local fade_widget = wibox.widget {
    {
        id = 'icon',
        image = '/usr/share/icons/Yaru/24x24/apps/org.gnome.PowerStats.png',
        widget = wibox.widget.imagebox
    },
    {
        id = 'text',
        text = 'Click to fade',
        widget = wibox.widget.textbox
    },
    spacing = 4,
    layout = wibox.layout.fixed.horizontal,
    toggle_fade = function(self, is_fade)
        self:get_children_by_id('icon')[1]:set_opacity(is_fade and 0.2 or 1)
        self:get_children_by_id('icon')[1]:emit_signal('widget::redraw_needed')
        self:get_children_by_id('text')[1]:set_opacity(is_fade and 0.2 or 1)
        self:get_children_by_id('text')[1]:emit_signal('widget::redraw_needed')
    end
}

-- on click
local faded = true
fade_widget:connect_signal('button::press', function(c)
    faded = not faded
    c:toggle_fade(not faded)
end)

-- on hover
fade_widget:toggle_fade(true)
fade_widget:connect_signal('mouse::enter', function(c) c:toggle_fade(false) end)
fade_widget:connect_signal('mouse::leave', function(c) c:toggle_fade(true) end)
```

## How it works

Let's start by creating a simple widget which has an icon and some text:


```lua
local fade_widget = wibox.widget {
    {
        image = '/usr/share/icons/Yaru/24x24/apps/org.gnome.PowerStats.png',
        widget = wibox.widget.imagebox
    },
    {
        text = 'Click to fade',
        widget = wibox.widget.textbox
    },
    spacing = 4,
    layout = wibox.layout.fixed.horizontal
}
```

Fade effect can be achieved by lowering the opacity of the widget. Luckily both [textbox](https://awesomewm.org/doc/api/classes/wibox.widget.textbox.html) and [imagebox](https://awesomewm.org/doc/api/classes/wibox.widget.imagebox.html) have opacity property, which is set to 1 by default. The cleanest way to change widget's property (or properties of nested widgets) is to add a function which will hide all the ugliness of accessing the nested widgets inside and expose a clean API outside:

{% highlight lua linenos %}
local fade_widget = wibox.widget {
    {
        id = 'icon',
        image = '/usr/share/icons/Yaru/24x24/apps/org.gnome.PowerStats.png',
        widget = wibox.widget.imagebox
    },
    {
        id = 'text',
        text = 'Click to fade',
        widget = wibox.widget.textbox
    },
    spacing = 4,
    layout = wibox.layout.fixed.horizontal,
    toggle_fade = function(self, is_fade)
        self:get_children_by_id('icon')[1]:set_opacity(is_fade and 0.2 or 1)
        self:get_children_by_id('icon')[1]:emit_signal('widget::redraw_needed')
        self:get_children_by_id('text')[1]:set_opacity(is_fade and 0.2 or 1)
        self:get_children_by_id('text')[1]:emit_signal('widget::redraw_needed')
    end
}
{% endhighlight %}

Few things to note here:

 - Added widget identifiers (line 3, 8) so that we can access them later - line 15-18. We are using JavaScript-like syntax, described in section _Accessing widgets_ of the [documentation](https://awesomewm.org/apidoc/documentation/03-declarative-layout.md.html)
 - When changing text in textbox the widget is redrawn automatically (same for the image in imagebox), however when changing opacity the redraw is not triggered, this is why we call it explicitly - line 16, 18. 

 Now we can easily trigger the fade effect on the widget by calling a `toggle_fade(true)` method. The only thing left is to add a mouse handler:

  - to toggle on mouse click

```lua
local faded = true
fade_widget:connect_signal('button::press', function(c)
    faded = not faded
    c:toggle_fade(not faded)
end)
```
  - to toggle on hover:

```lua
fade_widget:toggle_fade(true)
fade_widget:connect_signal('mouse::enter', function(c)
    c:toggle_fade(false)
end)
fade_widget:connect_signal('mouse::leave', function(c)
    c:toggle_fade(true)
end)
```
