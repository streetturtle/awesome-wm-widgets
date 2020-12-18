---
layout: page
---

# Ellipsize

>Ellipsizes string to a given length
{:.filename}
```lua
local function ellipsize(text, length)
    return (text:len() > length and length > 0)
        and text:sub(0, length - 3) .. '...'
        or text
end
```