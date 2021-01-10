#!/usr/bin/env sh

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~ Concatinate video files ~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~

PROGNAME=$(basename "$0")
CONCAT="$HOME/Videos/concat.txt"

invalid_flag() {
    echo "$PROGNAME: invalid option -- '$OPTARG'
Try '$PROGNAME --help' for more information." 1>&2
    exit 1
}

get_help() {
    cat <<EOF
Usage: $PROGNAME [OPTION]...
Concatinate dolphin framedumps with optional BGM for the run
Example: $PROGNAME -af "Videos/Dumps/concat.txt"

Options:
  -a, --audio
  -f, --file=FILE           path to the concat file; defaults to ~/Videos/concat.txt
  -h, --help                display this help text and exit
  -v, --version             display version information and exit

Exit status:
 0  if OK,
 1  if invalid flag or missing option
 2  if invalid ffmpeg concat file
 3  if this error occurs, I don't know why it happened

Source code: <https://www.github.com/Mango0x45/mkwtt-rec>
EOF
    exit 0
}

get_version() {
    echo "$PROGNAME v1.1"
    exit 0
}

test_file() {
    if test ! -f "$1"; then
        echo "$PROGNAME: error opening file '$1'"
        exit 2
    fi
}

while getopts ":-:af:hv" FLAG; do
    case $FLAG in
    -)
        case $OPTARG in
        audio)
            AFLAG=1
            ;;
        file)
            CONCAT=$(eval echo \$$OPTIND)
            test_file "$CONCAT"
            ;;
        file=*)
            CONCAT=$(echo "$OPTARG" | cut -d "=" -f 2)
            test_file "$CONCAT"
            ;;
        help)
            get_help
            ;;
        version)
            get_version
            ;;
        *)
            invalid_flag
            ;;
        esac
        ;;
    a)
        AFLAG=1
        ;;
    f)
        CONCAT=$OPTARG
        test_file "$CONCAT"
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

if test "$AFLAG" -eq 1; then
    # Get an audio file for each video file
    for VIDEO in *.avi; do
        AUDIO="$(echo "$VIDEO" | cut -d '.' -f 1).wav"
        test -e "$VIDEO" || exit 3
        ffmpeg -i "$VIDEO" -c copy "$AUDIO"
    done

    # Overlay the custom BGM on the run's audio file
    ffmpeg -y -i run.wav -i bgm.wav -filter_complex amix=inputs=2:duration=shortest run2.wav
    mv run2.wav run.wav

    # Stick 'em all together
    sed 's/.avi/.wav/g' "$CONCAT" >"aconcat.txt"
    ffmpeg -f concat -safe 0 -i "$CONCAT" -an -c copy concat.avi
    ffmpeg -f concat -safe 0 -i "aconcat.txt" -c copy concat.wav
    ffmpeg -i concat.avi -i concat.wav -c copy output.avi

    # Cleanup
    rm "$CONCAT" concat.avi ./*.wav
else
    ffmpeg -f concat -safe 0 -i "$CONCAT" -c copy output.avi
fi
