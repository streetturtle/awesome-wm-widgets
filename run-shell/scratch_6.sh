#!/usr/bin/env bash

#IMAGE=/tmp/i3lock.png
#SCREENSHOT="scrot -u $IMAGE" # 0.46s
#
## Alternate screenshot method with imagemagick. NOTE: it is much slower
## SCREENSHOT="import -window root $IMAGE" # 1.35s
#
## Here are some imagemagick blur types
## Uncomment one to use, if you have multiple, the last one will be used
#
## All options are here: http://www.imagemagick.org/Usage/blur/#blur_args
##BLURTYPE="0x5" # 7.52s
##BLURTYPE="0x2" # 4.39s
##BLURTYPE="5x2" # 3.80s
#BLURTYPE="2x8" # 2.90s
##BLURTYPE="2x3" # 2.92s
#
## Get the screenshot, add the blur and lock the screen with it
#$SCREENSHOT
#convert $IMAGE -blur $BLURTYPE $IMAGE
#echo 'done'


# --------------------------

RES=$(xrandr --current | grep '*' | uniq | awk '{print $1}')
RNDM=$(uuidgen)
IMAGE="/tmp/i3lock$RNDM.png"

if [[ $1 != "" ]]; then
    TEXT=$1
fi

ffmpeg -loglevel panic -f x11grab -video_size 1920x1060 -grab_y 20 -y -i $DISPLAY -filter_complex "boxblur=5" -vframes 1 $IMAGE

echo $RNDM
