#!/bin/bash
#
# ffmpeg video slideshow script with vertical stack transition v1 (11.12.2018)
#
# Copyright (c) 2017-2018, Taner Sener (https://github.com/tanersener)
#
# This work is licensed under the terms of the MIT license. For a copy, see <https://opensource.org/licenses/MIT>.
#

# SCRIPT OPTIONS - CAN BE MODIFIED
WIDTH=1280
HEIGHT=720
FPS=30
TOTAL_DURATION=10           # ALSO CONTROLS THE SPEED
BACKGROUND_COLOR="black"
DIRECTION=2                 # 1=TOP TO BOTTOM, 2=BOTTOM TO TOP
INCLUDE_INTRO=1             # START WITH EMPTY SCREEN
INCLUDE_OUTRO=0             # END WITH EMPTY SCREEN

# PHOTO OPTIONS - ALL FILES UNDER photos FOLDER ARE USED - USE sort TO SPECIFY A SORTING MECHANISM
# PHOTOS=`find ../photos/* | sort -r`
PHOTOS=`find ../photos/*`

############################
# DO NO MODIFY LINES BELOW
############################

# CALCULATE LENGTH MANUALLY
let PHOTOS_COUNT=0
for photo in ${PHOTOS}; do (( PHOTOS_COUNT+=1 )); done

if [[ ${PHOTOS_COUNT} -lt 2 ]]; then
    echo "Error: photos folder should contain at least two photos"
    exit 1;
fi

echo -e "\nVideo Slideshow Info\n------------------------\nPhoto count: ${PHOTOS_COUNT}\nDimension: ${WIDTH}x${HEIGHT}\nFPS: 30\nTotal duration: ${TOTAL_DURATION} s\n"

START_TIME=$SECONDS

# 1. START COMMAND
FULL_SCRIPT="ffmpeg -y "

# 2. ADD INPUTS
for photo in ${PHOTOS}; do
    FULL_SCRIPT+="-loop 1 -i ${photo} "
done

# 3. ADD BACKGROUND COLOR SCREEN INPUT
FULL_SCRIPT+="-f lavfi -i color=${BACKGROUND_COLOR}:s=${WIDTH}x${HEIGHT} "

# 4. START FILTER COMPLEX
FULL_SCRIPT+="-filter_complex \""

# 5. PREPARING SCALED INPUTS
for (( c=0; c<${PHOTOS_COUNT}; c++ ))
do
    FULL_SCRIPT+="[${c}:v]setpts=PTS-STARTPTS,scale=trunc(iw/2)*2:trunc(ih/2)*2,scale=${WIDTH}:-1,setsar=sar=1/1[stream$((c+1))];"
done

STACKED_INPUTS=""
declare -i INTRO_OUTRO_COUNT=0

# 6. BEGIN STACK INPUTS
if [[ ${INCLUDE_INTRO} -eq 1 ]]; then
    STACKED_INPUTS+="[${PHOTOS_COUNT}:v]"
    INTRO_OUTRO_COUNT+=1;
fi

for (( c=1; c<=${PHOTOS_COUNT}; c++ ))
do
    STACKED_INPUTS+="[stream${c}]"
done

if [[ ${INCLUDE_OUTRO} -eq 1 ]]; then
    STACKED_INPUTS+="[${PHOTOS_COUNT}:v]"
    INTRO_OUTRO_COUNT+=1;
fi

# 7. END STACK INPUTS
FULL_SCRIPT+="${STACKED_INPUTS}vstack=inputs=$((${PHOTOS_COUNT}+${INTRO_OUTRO_COUNT}))[stack];"

# 8. SLIDE STACK
case ${DIRECTION} in
    1)
        FULL_SCRIPT+="[${PHOTOS_COUNT}:v][stack]overlay=x=0:y='-(overlay_h-${HEIGHT})+(overlay_h-${HEIGHT})*t/${TOTAL_DURATION}',trim=duration=${TOTAL_DURATION},format=yuv420p[video]\""
    ;;
    *)
        FULL_SCRIPT+="[${PHOTOS_COUNT}:v][stack]overlay=x=0:y='-(overlay_h-${HEIGHT})*t/${TOTAL_DURATION}',trim=duration=${TOTAL_DURATION},format=yuv420p[video]\""
    ;;
esac

# 9. END
FULL_SCRIPT+=" -map [video] -vsync 2 -async 1 -rc-lookahead 0 -g 0 -profile:v main -level 42 -c:v libx264 -r ${FPS} ../transition_stack_vertical.mp4"

eval ${FULL_SCRIPT}

ELAPSED_TIME=$(($SECONDS - $START_TIME))

echo -e '\nSlideshow created in '$ELAPSED_TIME' seconds\n'