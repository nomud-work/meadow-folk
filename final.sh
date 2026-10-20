#!/bin/bash
# Final renders. Stills: 2560x1440 supersampled -> 1920x1080 (lanczos). Movie: 720p native.
cd "$(dirname "$0")"
log=final/render_log.txt; : > $log
r() { local res=$1 name=$2; shift 2; local t0=$(date +%s%N)
  TMO=900 ./run.sh $res res://main.tscn "$@" --out=raw_$name 2>&1 | grep -E "STILL|BUILD|TRIS|ERROR" | tee -a $log
  ffmpeg -loglevel error -y -i out/raw_$name.png -vf scale=1920:1080:flags=lanczos final/$name.png
  echo "WALL $name $(( ($(date +%s%N) - t0) / 1000000 )) ms" | tee -a $log; }
for k in boy girl spirit; do
  r 2560x1440 hero_$k --mode=hero --char=$k
  r 2560x1440 face_$k --mode=face --char=$k
done
r 2560x1440 group_scene --mode=group
for s in 0 1 2 3; do r 2560x1440 bd$s --mode=breakdown --char=boy --stage=$s; done
F=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf
[ -f $F ] || F=$(fc-list | grep -i "dejavu" | head -1 | cut -d: -f1)
lab() { echo "crop=620:1080:650:0,drawtext=fontfile=$F:text='$2':x=(w-tw)/2:y=40:fontsize=40:fontcolor=white:borderw=3:bordercolor=0x2a1a14"; }
ffmpeg -loglevel error -y -i final/bd0.png -i final/bd1.png -i final/bd2.png -i final/bd3.png -filter_complex \
 "[0]$(lab 0 '1 flat albedo')[a];[1]$(lab 1 '2 cel bands')[b];[2]$(lab 2 '3 + ink outline')[c];[3]$(lab 3 '4 final')[d];[a][b][c][d]hstack=4" final/breakdown.png
rm -f final/bd?.png
echo DONE | tee -a $log
