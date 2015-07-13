## Battery widget
Simple and easy-to-install widget for Awesome Window Manager.

Basically this widget consist of an icon which shows the battery status: ![Battery Widget](./batWid1.png)

And a pop-up window, which shows when you hover over it: ![Battery Widget](./batWid2.png)

## Installation

This widget ueses the output of acpi tool.

- install `acpi` tool:
-
{% highlight bash %}
sudo apt-get install acpi
{% endhighlight %}

- clone/copy battery.lua file and battery-icons folder to your ~/home/username/.config/awesome/ folder;

- add battery widget to your wibox in rc.lua:

{% highlight lua%}
right_layout:add(batteryIcon)
{% endhighlight %}
