#!/bin/sh

[ -z "$1" ] && echo "Please set an input file." && exit -1

FORMAT=scale=1280:720,fps=24000/10001
ffmpeg -i $1 -an -t 10 -f rawvideo -pix_fmt yuv422p16le -vf $FORMAT - | \
    ../build/prenc -f $FORMAT `basename $0 .sh`.mov
