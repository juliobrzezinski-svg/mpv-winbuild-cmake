#!/usr/bin/env bash
# videoSport: checks a built ffmpeg.exe/ffprobe.exe (run on Windows, e.g. Git Bash).
# Usage: videosport-ffmpeg/check.sh <dir with ffmpeg.exe> <outdir> [hevc_sample] [av1_sample]
# Writes ffmpeg -version/-buildconf/-encoders/-decoders/-filters to <outdir> and runs the checks videoSport needs.
set -uo pipefail
BIN=$(cd "$1" && pwd); OUT=$(mkdir -p "$2" && cd "$2" && pwd); HEVC=${3:-}; AV1=${4:-}
[[ -n "$HEVC" && -f "$HEVC" ]] && HEVC="$(cd "$(dirname "$HEVC")" && pwd)/$(basename "$HEVC")"
[[ -n "$AV1" && -f "$AV1" ]] && AV1="$(cd "$(dirname "$AV1")" && pwd)/$(basename "$AV1")"
FF="$BIN/ffmpeg.exe"; FP="$BIN/ffprobe.exe"
fail=0
ok()  { echo "PASS: $*"; }
bad() { echo "FAIL: $*"; fail=1; }
run() { "$@" 2>&1 | tr -d '\r'; }

run "$FF" -hide_banner -version   > "$OUT/ffmpeg-version.txt"
run "$FF" -hide_banner -buildconf > "$OUT/ffmpeg-buildconf.txt"
run "$FF" -hide_banner -encoders  > "$OUT/ffmpeg-encoders.txt"
run "$FF" -hide_banner -decoders  > "$OUT/ffmpeg-decoders.txt"
run "$FF" -hide_banner -filters   > "$OUT/ffmpeg-filters.txt"
run "$FF" -hide_banner -demuxers  > "$OUT/ffmpeg-demuxers.txt"
run "$FF" -hide_banner -muxers    > "$OUT/ffmpeg-muxers.txt"
run "$FP" -hide_banner -version   > "$OUT/ffprobe-version.txt"
head -1 "$OUT/ffmpeg-version.txt"

has() { # has <file> <name> : name appears as the 2nd column of a codec/filter/format list
    awk -v n="$2" '$2==n{f=1} END{exit !f}' "$1"
}
for e in libx264 aac libvpx-vp9 libopus;  do has "$OUT/ffmpeg-encoders.txt" "$e" && ok "encoder $e" || bad "encoder $e"; done
for d in hevc h264 aac libdav1d;          do has "$OUT/ffmpeg-decoders.txt" "$d" && ok "decoder $d" || bad "decoder $d"; done
for f in scale setpts setsar anullsrc fps; do has "$OUT/ffmpeg-filters.txt"  "$f" && ok "filter $f"  || bad "filter $f"; done
for m in concat mov,mp4,m4a,3gp,3g2,mj2 matroska,webm; do has "$OUT/ffmpeg-demuxers.txt" "$m" && ok "demuxer $m" || bad "demuxer $m"; done
for m in mp4 webm mov; do has "$OUT/ffmpeg-muxers.txt" "$m" && ok "muxer $m" || bad "muxer $m"; done
grep -q -- '--enable-gpl' "$OUT/ffmpeg-buildconf.txt" && ok "buildconf has --enable-gpl" || bad "buildconf --enable-gpl"

T="$OUT/tests"; mkdir -p "$T"; cd "$T" || exit 1
probe() { run "$FP" -v error -show_entries stream=codec_name:format=duration -of csv=p=0 "$1" | tr '\n' ' '; }

run "$FF" -y -v error -f lavfi -i testsrc2=size=1280x720:rate=30 -f lavfi -i sine=frequency=440:sample_rate=48000 -t 3 \
    -c:v libx264 -preset veryfast -crf 20 -pix_fmt yuv420p -c:a aac -movflags +faststart a.mp4 > enc-mp4.log
p=$(probe a.mp4); echo "a.mp4: $p"; [[ "$p" == *h264* && "$p" == *aac* ]] && ok "encode MP4 H.264/AAC (veryfast crf 20)" || bad "encode MP4"

run "$FF" -y -v error -f lavfi -i testsrc2=size=640x360:rate=25 -f lavfi -i sine=frequency=660:sample_rate=48000 -t 2 \
    -c:v libx264 -preset medium -crf 14 -pix_fmt yuv420p -c:a aac -movflags +faststart b.mp4 > enc-mp4b.log
p=$(probe b.mp4); [[ "$p" == *h264* ]] && ok "encode MP4 H.264 (medium crf 14)" || bad "encode MP4 medium"

run "$FF" -y -v error -f lavfi -i testsrc2=size=640x360:rate=25 -f lavfi -i sine=frequency=440:sample_rate=48000 -t 3 \
    -c:v libvpx-vp9 -b:v 0 -crf 33 -deadline realtime -cpu-used 8 -c:a libopus a.webm > enc-webm.log
p=$(probe a.webm); echo "a.webm: $p"; [[ "$p" == *vp9* && "$p" == *opus* ]] && ok "encode WebM VP9/Opus" || bad "encode WebM"

# scale/setsar/setpts, -r + -fps_mode cfr, anullsrc for a silent track
run "$FF" -y -v error -i b.mp4 -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=48000 -map 0:v -map 1:a -shortest \
    -vf "scale=1280:720,setsar=1,setpts=PTS-STARTPTS" -r 30 -fps_mode cfr -c:v libx264 -preset veryfast -crf 20 \
    -pix_fmt yuv420p -c:a aac c.mp4 > enc-filters.log
p=$(probe c.mp4); [[ "$p" == *h264* && "$p" == *aac* ]] && ok "scale/setsar/setpts/-r/-fps_mode cfr/anullsrc" || bad "filters"

printf "file 'a.mp4'\nfile 'a.mp4'\n" > list.txt
run "$FF" -y -v error -f concat -safe 0 -i list.txt -c copy -movflags +faststart joined.mp4 > concat.log
p=$(probe joined.mp4); echo "joined.mp4: $p"; [[ "$p" == *h264* ]] && ok "concat demuxer + -c copy" || bad "concat"

if [[ -n "$HEVC" && -f "$HEVC" ]]; then
    run "$FF" -v error -i "$HEVC" -f null - > dec-hevc.log
    [[ ! -s dec-hevc.log ]] && ok "decode HEVC sample ($(probe "$HEVC"))" || { cat dec-hevc.log; bad "decode HEVC"; }
else echo "SKIP: HEVC decode (no sample given; this binary has no HEVC encoder)"; fi
if [[ -n "$AV1" && -f "$AV1" ]]; then
    run "$FF" -v error -c:v libdav1d -i "$AV1" -f null - > dec-av1.log
    [[ ! -s dec-av1.log ]] && ok "decode AV1 sample with libdav1d ($(probe "$AV1"))" || { cat dec-av1.log; bad "decode AV1"; }
else echo "SKIP: AV1 decode (no sample given; this binary has no AV1 encoder)"; fi

[[ $fail == 0 ]] && echo "ALL CHECKS PASSED" || echo "SOME CHECKS FAILED"
exit $fail
