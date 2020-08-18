# GitHub Activity Widget

Widget shows recent activities on GitHub. It is very similar to the GitHub's "All activity" feed on the main page:

<p align="center">
  <img src="https://github.com/streetturtle/awesome-wm-widgets/raw/master/github-activity-widget/screenshot.png">
</p>

Mouse click on the item opens repo/issue/pr depending on the type of the activity. Mouse click on user's avatar opens user GitHub profile.

## Customization

It is possible to customize widget by providing a table with all or some of the following config parameters:

| Name | Default | Description |
|---|---|---|
| `icon` | github.png from the widget sources | Widget icon displayed on the wibar |
| `username` | your username | Required parameter |
| `number_of_events` | 10 | Number of events to display in the list |

## Installation

Clone repo under **~/.config/awesome/** and add widget in **rc.lua**:

```lua
local github_activity_widget = require("awesome-wm-widgets.github-activity-widget.github-activity-widget")
...
s.mytasklist, -- Middle widget
	{ -- Right widgets
    	layout = wibox.layout.fixed.horizontal,
        ...
        -- default
        github_activity_widget{
            username = 'streetturtle',
        },
        -- customized
        github_activity_widget{
            username = 'streetturtle',
            number_of_events = 5
        },

```


## How it works

Everything starts with this timer, which gets recent activities by calling GitHub [Events API](https://developer.github.com/v3/activity/events/) and stores the response under /.cache/awmw/github-activity-widget/activity.json directory:

```lua
gears.timer {
    timeout   = 600,   -- calls every ten minutes
    call_now  = true,
    autostart = true,
    callback  = function()
        spawn.easy_async(string.format(UPDATE_EVENTS_CMD, username, CACHE_DIR), function(stdout, stderr)
            if stderr ~= '' then show_warning(stderr) return end
        end)
    end
}
```

There are several reasons to store output in a file and then use it as a source to build the widget, instead of calling it everytime the widget is opened: 
 - activity feed does not update that often
 - events API doesn't provide filtering of fields, so the output is quite large (300 events)
 - it's much faster to read file from filesystem

 Next important part is **rebuild_widget** function, which is called when mouse button clicks on the widget on the wibar. It receives a json string which contains first n events from the cache file. Those events are processed by `jq` (get first n events, remove unused fields, slightly change the json structure to simplify serialization to lua table). And then it builds a widget, row by row in a loop. To display the text part of the row we already have all neccessary information in the json string which was converted to lua table. But to show an avatar we should download it first. This is done in the following snippet. First it creates a template and then checks if file already exists, and sets it in template, otherwise, downloads it asynchronously and only then sets in:

 ```lua
local avatar_img = wibox.widget {
    resize = true,
    forced_width = 40,
    forced_height = 40,
    widget = wibox.widget.imagebox
}

if gfs.file_readable(path_to_avatar) then
    avatar_img:set_image(path_to_avatar)
else
    -- download it first
    spawn.easy_async(string.format(
            DOWNLOAD_AVATAR_CMD,
            CACHE_DIR,
            event.actor.id,
            event.actor.avatar_url), 
            -- and then set
            function() avatar_img:set_image(path_to_avatar) end)
end
 ```
