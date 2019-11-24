# Jira widget

The widget shows the number of assigned tickets to the user  and when clicked shows them in the list with some additional information. When item in the list is clicked - it opens the issue in browser 

2![screenshot](cpu.gif)

## How it works

Widget users cURL to query JIRA's REST API. In order to be authenticated, widget uses netrc feature of the cURL, which is basically to store basic auth credentials in a .netrc file in home folder. 

## Customization

It is possible to customize widget by providing a table with all or some of the following config parameters:

| Name | Default | Description |
|---|---|---|
| `host` | Required | Ex: _http://jira.tmnt.com_ |
| `query` | `jql=assignee=currentuser() AND resolution=Unresolved` | JQL query |
| `icon` | `~/.config/awesome/awesome-wm-widgets/jira-widget/jira-mark-gradient-blue.svg` | Path to the icon |

## Installation

Clone/download repo and use widget in **rc.lua**:

```lua
local jira_widget = require("awesome-wm-widgets.jira-widget.jira")
...
s.mytasklist, -- Middle widget
	{ -- Right widgets
    	layout = wibox.layout.fixed.horizontal,
		...
		-- default
		jira_widget({host = 'http://jira.tmnt.com'}),
		...
```
