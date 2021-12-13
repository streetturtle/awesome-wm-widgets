# GitHub PRs Widget

<p align="center">
  <a href="https://github.com/streetturtle/awesome-wm-widgets/labels/github-prs" target="_blank"><img alt="GitHub issues by-label" src="https://img.shields.io/github/issues/streetturtle/awesome-wm-widgets/github-prs"></a>
</p>

The widget shows the number of pull requests assigned to the user and when clicked shows additional information, such as
 - author's name and avatar (opens user profile page when clicked);
 - PR name (opens MR when clicked);
 - name of the repository;
 - when was created;
 - number of comments;

<p align="center">
<img src="https://github.com/streetturtle/awesome-wm-widgets/raw/master/github-prs-widget/screenshots/screenshot1.png">
</p>

## Customization

It is possible to customize widget by providing a table with all or some of the following config parameters:

| Name | Default | Description |
|---|---|---|
| `reviewer` | Required | github user login |

## Installation

Install and setup [GitHub CLI](https://cli.github.com/)
Clone/download repo and use widget in **rc.lua**:

```lua
local github_prs_widget = require("awesome-wm-widgets.github-prs-widget")
...
s.mytasklist, -- Middle widget
{ -- Right widgets
    layout = wibox.layout.fixed.horizontal,
    ...
    github_prs_widget {
        reviewer = 'streetturtle'
    },
}
...
```
