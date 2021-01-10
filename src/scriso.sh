#!/usr/bin/env sh

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~ Automatically edit MKWii runs recording through Dolphin ~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Set directories
PROGNAME=$(basename "$0")
DOLPHIN_DIR="$HOME/.local/share/dolphin-emu/Dump"
VID_DIR="$HOME/Videos"

invalid_flag() {
    echo "$PROGNAME: invalid option -- '$OPTARG'
Try '$PROGNAME --help' for more information." 1>&2
    exit 1
}

get_help() {
    cat <<EOF
Usage: $PROGNAME [OPTION]...
Merge a Dolphin framedump and audiodump into one 4K video with optional effects
Example: $PROGNAME --video="~/Videos/MKWTTs"

Options:
  -d, --dolphin=DIRECTORY   path to Dolphin's dump directory; defaults to
                              ~/.local/share/dolphin-emu/Dump
  -h, --help                display this help text and exit
  -v, --version             display version information and exit
      --video=DIRECTORY     path to the videos directory; defaults to ~/Videos

Exit status:
 0  if OK,
 1  if invalid flag or missing option
 2  if invalid directory
 3  if conflicting framedumps

Source code: <https://www.github.com/Mango0x45/mkwtt-rec>
EOF
    exit 0
}

get_version() {
    echo "$PROGNAME v1.1"
    exit 0
}

test_dir() {
    if test ! -d "$1"; then
        echo "$PROGNAME: invalid directory '$1'"
        exit 2
    fi
}

while getopts ":-:d:hv" FLAG; do
    case $FLAG in
    -)
        case $OPTARG in
        dolphin)
            DOLPHIN_DIR=$(eval echo \$$OPTIND)
            test_dir "$DOLPHIN_DIR"
            ;;
        dolphin=*)
            DOLPHIN_DIR=$(echo "$OPTARG" | cut -d "=" -f 2)
            test_dir "$DOLPHIN_DIR"
            ;;
        help)
            get_help
            ;;
        version)
            get_version
            ;;
        video)
            VID_DIR=$(eval echo \$$OPTIND)
            test_dir "$VID_DIR"
            ;;
        video=*)
            VID_DIR=$(echo "$OPTARG" | cut -d "=" -f 2)
            test_dir "$VID_DIR"
            ;;
        *)
            invalid_flag
            ;;
        esac
        ;;
    d)
        DOLPHIN_DIR=$OPTARG
        test_dir "$DOLPHIN_DIR"
        ;;
    h)
        get_help
        ;;
    v)
        get_version
        ;;
    *)
        invalid_flag
        ;;
    esac
done

# Compatibility with dolphin developer releases
cd "$DOLPHIN_DIR/Frames" || exit 1

for f in ./*; do
    case $f in
    ./RMCE01*)
        COUNT=$((COUNT + 1))
        ;;
    esac
done

if test "$COUNT" -le 1; then
    mv RMCE01* framedump0.avi 2>/dev/null
else
    echo "Multiple framedumps detected! Exiting."
    exit 3
fi

# Set video type
printf "Video Type: [title/run/fullvid/none]: "
read -r VIDEO_TYPE

case "$(echo "$VIDEO_TYPE" | tr '[:upper:]' '[:lower:]')" in
title)
    ffmpeg -loglevel quiet -y -i "$DOLPHIN_DIR/Frames/framedump0.avi" \
        -i "$DOLPHIN_DIR/Audio/dspdump.wav" -c:v h264_nvenc \
        -profile:v high -preset slow -rc vbr_2pass -qmin 17 -qmax 22 \
        -2pass 1 -c:a:0 copy -b:v 100000k \
        -filter:v fade=in:0:90,scale=3840:2160:flags=neighbor,fade=in:0:90 \
        "$VID_DIR/output.avi"
    ;;
fullvid | run)
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
none)
    ffmpeg -loglevel quiet -y -i "$DOLPHIN_DIR/Frames/framedump0.avi" \
        -i "$DOLPHIN_DIR/Audio/dspdump.wav" -c:v h264_nvenc \
        -profile:v high -preset slow -rc vbr_2pass -qmin 17 -qmax 22 \
        -2pass 1 -c:a:0 copy -b:v 100000k \
        -filter:v scale=3840:2160:flags=neighbor \
        "$VID_DIR/output.avi"
    ;;
*)
    echo Invalid selection
    ;;
esac

# Cleanup
test -e "$VID_DIR/temp.avi" && rm "$VID_DIR/temp.avi"
