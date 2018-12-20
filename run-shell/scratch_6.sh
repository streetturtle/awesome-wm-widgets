#!/usr/bin/env bash

#RES=$(xrandr --current | grep '*' | uniq | awk '{print $1}')
RNDM=$(uuidgen)
IMAGE="/tmp/i3lock-$RNDM.png"


## blur
#ffmpeg -loglevel panic -f x11grab -video_size 1920x1060 -y -i :0.0+0,20 -filter_complex "boxblur=9" -vframes 1 $IMAGE
## pixelate
ffmpeg  -loglevel panic -f x11grab -video_size 1920x1060 -y -i :0.0+$1,20 -vf frei0r=pixeliz0r -vframes 1 $IMAGE

echo $RNDM