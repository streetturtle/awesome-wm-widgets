# Email widget

This widget consists of an icon with counter which shows number of unread emails: ![email icon](./em-wid-1.png)
and a popup message which appears when mouse hovers over an icon: ![email popup](./em-wid-2.png)

## Installation
1. Clone this repository to your awesome config folder:

```bash
git clone https://github.com/streetturtle/awesome-wm-widgets/email-widget ~/.config/awesome/email-widget
```
2. Make virtual environment and install dependencies:

```bash
cd ~/.config/awesome/email-widget
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```
3. Fill .env file with your credentials:

```bash
cp .env.example .env
```
4. Add widget to awesome:

```lua
local email_widget = require("email-widget.email")
...
s.mytasklist, -- Middle widget
	{ -- Right widgets
		layout = wibox.layout.fixed.horizontal,
		...
		email_widget,
		...      
```

If you want to reduce time of getting emails, you can change maximum number of emails to be fetched in .env file. Default is 10.
If you want to configure width of popup window, you can change this line in email.lua file:

```lua
                width = 800,
```
After this you can change MAX_BODY_LENGTH variable in .env file to change number of characters to be displayed in popup window. Default is 100.
Next step is restarting awesome. You can do this by pressing Mod+Ctrl+r.

## How it works

This widget uses the output of two python scripts, first is called every 20 seconds - it returns number of unread emails and second is called when mouse hovers over an icon and displays content of those emails. For both of them you'll need to provide your credentials and imap server. For testing, they can simply be called from console:

``` bash
python ~/.config/awesome/email-widget/count_unread_emails.py 
python ~/.config/awesome/email-widget/read_emails.py 
```
