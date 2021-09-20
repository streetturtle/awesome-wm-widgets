# Gitlab widget

<p align="center">
  <a href="https://github.com/streetturtle/awesome-wm-widgets/labels/gitlab" target="_blank"><img alt="GitHub issues by-label" src="https://img.shields.io/github/issues/streetturtle/awesome-wm-widgets/gitlab"></a>
</p>

The widget shows the number of merge requests assigned to the user and when clicked shows additional information, such as 
 - author's name and avatar (opens user profile page when clicked);
 - MR name (opens MR when clicked);
 - source and target branches;
 - when was created;
 - number of comments;
 - number of approvals.

![screenshot](./screenshot.png)

## Customization

It is possible to customize widget by providing a table with all or some of the following config parameters:

| Name | Default | Description |
|---|---|---|
| `icon` | `./icons/gitlab-icon.svg` | Path to the icon |
| `host` | Required | e.g _https://gitlab.yourcompany.com_ |
| `access_token` | Required | e.g _h2v531iYASDz6McxYk4A_ |
| `timeout` | 60 | How often in seconds the widget should be refreshed |

_Note:_
 - to get the access token, go to **User Settings** -> **Access Tokens** and generate a token with **api** scope

## Installation

Clone/download repo and use widget in **rc.lua**:

```lua
local gitlab_widget = require("awesome-wm-widgets.gitlab-widget.gitlab")
...
s.mytasklist, -- Middle widget
	{ -- Right widgets
    	layout = wibox.layout.fixed.horizontal,
		...
		-- default
        gitlab_widget{
            host = 'https://gitlab.yourcompany.com',
            access_token = 'h2v531iYASDz6McxYk4A'
        },
		...
```
