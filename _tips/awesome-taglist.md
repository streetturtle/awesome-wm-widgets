---
layout: page
---

Here is nice-looking and super easy way to customize taglist. The idea is simple - literally write 'awesome' or 'awesomewm' (if you want to keep 9 tags) in the taglist using characters from the Awesome logo.

To do it you need to install a font which was generated from the svg images of the letters from the logo. Download it from [here]({{ "/assets/fonts/awesomewm-font.ttf" | relative_url }}) and place it under **~/.local/share/fonts**. Then name your tags in rc.lua using it. The font has two types of letters: uppercase are for the bold characters:

```lua
awful.tag({ "A", "W", "E", "S", "O", "M", "E", "W", "M"},
```

![awesome-taglist]({{ "/assets/img/tips/awesome-taglist-1.png" | relative_url }}){:.center-image}

and lowercase for the outline characters:

```lua
awful.tag({ "a", "w", "e", "s", "o", "m", "e", "w", "m"},
```

![awesome-taglist]({{ "/assets/img/tips/awesome-taglist-2.png" | relative_url }}){:.center-image}

To have same colors as on the screenshots, use following configuration:

>theme.lua
{:.filename}
```lua
theme.taglist_fg_focus    = "#3992af"
theme.taglist_fg_occupied = "#164b5d"
theme.taglist_fg_urgent   = "#ED7572"
theme.taglist_fg_empty    = "#828282"
theme.taglist_spacing     = 2
theme.taglist_font        = "awesomewm 11"
```
