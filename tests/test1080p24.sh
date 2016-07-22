#!/bin/sh

[ -z "$1" ] && echo "Please set an input file." && exit -1

FORMAT=scale=1920:1080,fps=24/1
ffmpeg -i $1 -an -t 10 -f rawvideo -pix_fmt yuv422p16le -vf $FORMAT - | \
    ../build/prenc -f $FORMAT `basename $0 .sh`.mov
