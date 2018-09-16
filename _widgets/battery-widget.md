---
layout: page
---
# Battery widget

Simple and easy-to-install widget for Awesome Window Manager.

This widget consists of:

 - an icon which shows the battery level:  
 ![Battery Widget]({{'/assets/img/screenshots/battery-wid-1.png' | relative_url }})
 - a pop-up window, which shows up when you hover over an icon:  
 ![Battery Widget]({{'/assets/img/screenshots/battery-wid-2.png' | relative_url }})
 Alternatively you can use a tooltip (check the code):  
 ![Battery Widget]({{'/assets/img/screenshots/battery-wid-22.png' | relative_url }})
 - a pop-up warning message which appears on bottom right corner when battery level is less that 15% (you can get the image [here](https://vk.com/images/stickers/1933/512.png)):  
 ![Battery Widget]({{'/assets/img/screenshots/battery-wid-3.png' | relative_url }})

Note that widget uses the Arc icon theme, so it should be [installed](https://github.com/horst3180/arc-icon-theme#installation) first under **/usr/share/icons/Arc/** folder.

## Installation

This widget reads the output of acpi tool.
- install `acpi` and check the output:

{% highlight bash %}

{% endhighlight %}


```bash
$ sudo apt-get install acpi
$ acpi
Battery 0: Discharging, 66%, 02:34:06 remaining
```

Then refer to the [installation](https://github.com/streetturtle/awesome-wm-widgets#installation) section of the repo.
