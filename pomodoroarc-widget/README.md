# Pomodoro Widget

:construction: This widget is under construction :construction_worker:

## Installation

This widget is based on [@jsspencer](https://github.com/jsspencer)' [pomo](https://github.com/jsspencer/pomo) - a simple pomodoro timer.
So first install/clone it anywhere you like, then either 
 - in widget's code provide path to the pomo.sh, or
 - add pomo.sh to the PATH, or
 - make a soft link in /usr/local/bin/ to it:
 ```bash
 sudo ln -sf /opt/pomodoro/pomo.sh /usr/local/bin/pomo
 ``` 

Note that by default widget's code expects third way and calls script by `pomo`.