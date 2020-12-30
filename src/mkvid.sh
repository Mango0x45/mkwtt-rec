#!/usr/bin/env sh

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~ Automatically edit MKWii runs recording through Dolphin ~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Set directories
DOLPHIN_DIR="$HOME/.local/share/dolphin-emu/Dump"
VID_DIR="$HOME/Videos"

# Set video type
printf "Video Type: [title/run/fullvid/none]: "
read -r VIDEO_TYPE

# Compatibility with dolphin developer releases
cd "$DOLPHIN_DIR/Frames" || exit 1
mv RMCE01* framedump0.avi 2>/dev/null

case "$VIDEO_TYPE" in
"title")
    ffmpeg -loglevel quiet -y -i "$DOLPHIN_DIR/Frames/framedump0.avi" \
        -i "$DOLPHIN_DIR/Audio/dspdump.wav" -c:v h264_nvenc \
        -profile:v high -preset slow -rc vbr_2pass -qmin 17 -qmax 22 \
        -2pass 1 -c:a:0 copy -b:v 100000k \
        -filter:v fade=in:0:90,scale=3840:2160:flags=neighbor,fade=in:0:90 \
        "$VID_DIR/output.avi"
    ;;
"fullvid" | "run")
    # Calculate the start of the fade out
    ffmpeg -loglevel quiet -y -i "$DOLPHIN_DIR/Frames/framedump0.avi" \
        -filter:v scale=1:1 "$VID_DIR/temp.avi"
    DURATION=$(ffprobe -i "$VID_DIR/temp.avi" \
        -show_entries stream=codec_type,duration \
        -of compact=p=0:nk=1 | awk -F\| '{print $2}')
    FADE_OUT_START=$(echo "$DURATION / .016666666 - 150" | bc)

    # Runs have fade out, full videos have fade in and fade out
    if test "$VIDEO_TYPE" = "run"; then
        ffmpeg -loglevel quiet -y -i "$DOLPHIN_DIR/Frames/framedump0.avi" \
            -i "$DOLPHIN_DIR/Audio/dspdump.wav" -c:v h264_nvenc \
            -profile:v high -preset slow -rc vbr_2pass -qmin 17 -qmax 22 \
            -2pass 1 -c:a:0 copy -b:v 100000k \
            -filter:v fade=out:"$FADE_OUT_START":90,scale=3840:2160:flags=neighbor,fade=in:0:90 \
            "$VID_DIR/output.avi"
    else
        ffmpeg -loglevel quiet -y -i "$DOLPHIN_DIR/Frames/framedump0.avi" \
            -i "$DOLPHIN_DIR/Audio/dspdump.wav" -c:v h264_nvenc \
            -profile:v high -preset slow -rc vbr_2pass -qmin 17 -qmax 22 \
            -2pass 1 -c:a:0 copy -b:v 100000k \
            -filter:v fade=in:0:90,fade=out:"$FADE_OUT_START":90,scale=3840:2160:flags=neighbor,fade=in:0:90 \
            "$VID_DIR/output.avi"
    fi
    ;;
"none")
    ffmpeg -loglevel quiet -y -i "$DOLPHIN_DIR/Frames/framedump0.avi" \
        -i "$DOLPHIN_DIR/Audio/dspdump.wav" -c:v h264_nvenc \
        -profile:v high -preset slow -rc vbr_2pass -qmin 17 -qmax 22 \
        -2pass 1 -c:a:0 copy -b:v 100000k \
        -filter:v scale=3840:2160:flags=neighbor,fade=in:0:90 \
        "$VID_DIR/output.avi"
    ;;
*)
    echo Invalid selection
    ;;
esac

# Cleanup
test -e "$VID_DIR/temp.avi" && rm "$VID_DIR/temp.avi"
