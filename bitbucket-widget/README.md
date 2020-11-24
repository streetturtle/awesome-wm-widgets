# Bitbucket widget

The widget shows the number of pull requests assigned to the user and when clicked shows them in the list with some additional information. When item in the list is clicked - it opens the pull request in the browser.

## How it works

Widget uses cURL to query Bitbucket's [REST API](https://developer.atlassian.com/bitbucket/api/2/reference/). In order to be authenticated, widget uses a [netrc](https://ec.haxx.se/usingcurl/usingcurl-netrc) feature of the cURL, which is basically allows storing basic auth credentials in a **.netrc** file in home folder. 

Bitbucket allows using [App Passwords](https://confluence.atlassian.com/bitbucket/app-passwords-828781300.html) (available in the account settings) - simply generate one for the widget and use it as password in **.netrc** file.

## Customization

It is possible to customize widget by providing a table with all or some of the following config parameters:

| Name | Default | Description |
|---|---|---|
| `icon` | `~/.config/awesome/awesome-wm-widgets/bitbucket-widget/bitbucket-icon-gradient-blue.svg` | Path to the icon |
| `host` | Required | e.g _http://api.bitbucket.org_ |
| `uuid` | Required | e.g _{123e4567-e89b-12d3-a456-426614174000}_ |
| `workspace` | Required | Workspace ID|
| `repo_slug` | Required | Repository slug |
| `timeout` | 60 | How often in seconds the widget refreshes |

Note:
 - host most likely should start with _api._
 - to get your UUID you may call `curl -s -n 'https://api.bitbucket.org/2.0/user'`

## Installation

Create a **.netrc** file in you home directory with following content:

```bash
machine api.bitbucket.org
login mikey@tmnt.com
password cowabunga
```

Then change file's permissions to 600 (so only you can read/write it):

```bash
chmod 600 ~/.netrc
```
And test if it works by calling the API:

```bash
curl -s -n 'https://api.bitbucket.org/2.0/repositories/'
```

Also to properly setup required parameters you can use `test_bitbucket_api.sh` script - it uses the same curl call as widget.

Then clone/download repo and use widget in **rc.lua**:

```lua
local bitbucket_widget = require("awesome-wm-widgets.bitbucket-widget.bitbucket")
...
s.mytasklist, -- Middle widget
	{ -- Right widgets
    	layout = wibox.layout.fixed.horizontal,
		...
		-- default
		bitbucket_widget({
		    host = 'https://api.bitbucket.org',
            uuid = '{123e4567-e89b-12d3-a456-426614174000}',
            workspace = 'workspace',
            repo_slug = 'slug'

		}}),
		...
```
