---
layout: page
---

# Battery widget
Simple and easy-to-install widget for Awesome Window Manager.

This widget consists of 

| ![Battery Widget](https://raw.githubusercontent.com/streetturtle/AwesomeWM/master/battery-widget/bat-wid-1.png) | an icon which shows the battery level |
| ![Battery Widget](https://raw.githubusercontent.com/streetturtle/AwesomeWM/master/battery-widget/bat-wid-2.png) | a pop-up window, which shows up when you hover over an icon |
| ![Battery Widget](https://raw.githubusercontent.com/streetturtle/AwesomeWM/master/battery-widget/bat-wid-3.png) | a pop-up warning message which appears on bottom right corner when battery level is less that 15% |

Note that widget uses the Arc icon theme, so it should be [installed](https://github.com/horst3180/arc-icon-theme#installation) first under **/usr/share/icons/Arc/** folder.

## Installation

This widget reads the output of acpi tool.
- install `acpi` and check the output:

{% highlight bash %}
$ sudo apt-get install acpi
$ acpi
Battery 0: Discharging, 66%, 02:34:06 remaining
{% endhighlight %}

- clone/copy **battery.lua** file to **~/.config/awesome/** folder;

- include **battery.lua** and add battery widget to your wibox in **rc.lua**:

{% highlight lua %}
require("battery")
...
s.mytasklist, -- Middle widget
	{ -- Right widgets
    	layout = wibox.layout.fixed.horizontal,
		...
		battery_widget,
		...      
{% endhighlight %}