---
layout: page
---

# To time ago

>Converts seconds to "time ago" represenation, like '1 hour ago'
{:.filename}
```lua
local function to_time_ago(seconds)
    local days = seconds / 86400
    if days > 1 then
        days = math.floor(days + 0.5)
        return days .. (days == 1 and ' day' or ' days') .. ' ago'
    end

    local hours = (seconds % 86400) / 3600
    if hours > 1 then
        hours = math.floor(hours + 0.5)
        return hours .. (hours == 1 and ' hour' or ' hours') .. ' ago'
    end

    local minutes = ((seconds % 86400) % 3600) / 60
    if minutes > 1 then
        minutes = math.floor(minutes + 0.5)
        return minutes .. (minutes == 1 and ' minute' or ' minutes') .. ' ago'
    end
end
```