#!/bin/sh

[ -z "$1" ] && echo "Please set an input file." && exit -1

FORMAT=scale=720:480,fps=30000/1001
ffmpeg -i $1 -an -t 10 -f rawvideo -pix_fmt yuv422p16le -vf $FORMAT - | \
    ../build/prenc -f $FORMAT,setdar=4/3,interlace `basename $0 .sh`.mov
