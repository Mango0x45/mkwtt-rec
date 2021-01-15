#!/usr/bin/env sh

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~ Automatically rename .rkg files for easy scrubbing ~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

PROGNAME=$(basename "$0")
GHOST_DIR="$HOME/Downloads"
WIISCRUB_DIR="$HOME/Documents/MKWRecording/WiiScrubber"

invalid_flag() {
    echo "$PROGNAME: invalid option -- '$OPTARG'
Try '$PROGNAME --help' for more information." 1>&2
    exit 1
}

get_help() {
    cat <<EOF
Usage: $PROGNAME [OPTION]...
Scrub a ghost file to be imported into Dolphin
Example: $PROGNAME -f "00m42s8430772 Mango Man.rkg" -t rDKJP

Options:
  -f, --file=FILE           path to the ghost file; defaults to ~/Downloads/*.rkg
  -h, --help                display this help text and exit
  -t, --track               the track the ghost was driven on; uses track name
                              abbrevations with a leading 'r' for retros such as
                              rGV2, DKSC, RR
  -v, --version             display version information and exit
  -w, --wiiscrub=DIRECTORY  directory containing the WiiScrubber executable;
                              defaults to ~/Documents/MKWRecording/WiiScrubber

Exit status:
 0  if OK,
 1  if invalid flag or missing option
 2  if invalid ghost file
 3  if invalid WiiScrubber directory
 4  if fails to launch wine

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
        echo "$PROGNAME: invalid ghost file '$1'"
        exit 2
    fi
}

test_dir() {
    if test ! -d "$1"; then
        echo "$PROGNAME: invalid directory '$1'"
        exit 3
    fi
}

while getopts ":-:f:ht:vw:" FLAG; do
    case $FLAG in
    -)
        case $OPTARG in
        file)
            FILE=$(eval echo \$$OPTIND)
            test_file "$FILE"
            ;;
        file=*)
            FILE=$(echo "$OPTARG" | cut -d "=" -f 2)
            test_file "$FILE"
            ;;
        help)
            get_help
            ;;
        track)
            TRACK=$(eval echo \$$OPTIND)
            ;;
        track=*)
            TRACK=$(echo "$OPTARG" | cut -d "=" -f 2)
            ;;
        version)
            get_version
            ;;
        wiiscrub)
            WIISCRUB_DIR=$(eval echo \$$OPTIND)
            test_dir "$WIISCRUB_DIR"
            ;;
        wiiscrub=*)
            WIISCRUB_DIR=$(echo "$OPTARG" | cut -d "=" -f 2)
            test_dir "$WIISCRUB_DIR"
            ;;
        *)
            invalid_flag
            ;;
        esac
        ;;
    f)
        FILE=$OPTARG
        test_file "$FILE"
        ;;
    h)
        get_help
        ;;
    t)
        TRACK=$OPTARG
        ;;
    v)
        get_version
        ;;
    w)
        WIISCRUB_DIR=$OPTARG
        ;;
    *)
        invalid_flag
        ;;
    esac
done

if test ! -n "$TRACK"; then
    printf "Track: "
    read -r TRACK
fi

# Case insensitive matching
case $(echo "$TRACK" | tr '[:lower:]' '[:upper:]') in
LC)
    TRACK_ID=00
    ;;
MMM)
    TRACK_ID=01
    ;;
MG)
    TRACK_ID=02
    ;;
TF)
    TRACK_ID=03
    ;;
MC)
    TRACK_ID=04
    ;;
CM)
    TRACK_ID=05
    ;;
DKSC | DKS)
    TRACK_ID=06
    ;;
WGM)
    TRACK_ID=07
    ;;
DC)
    TRACK_ID=08
    ;;
KC)
    TRACK_ID=09
    ;;
MT)
    TRACK_ID=11
    ;;
GV)
    TRACK_ID=10
    ;;
DDR)
    TRACK_ID=13
    ;;
MH)
    TRACK_ID=12
    ;;
BC)
    TRACK_ID=14
    ;;
RR)
    TRACK_ID=15
    ;;
RPB)
    TRACK_ID=24
    ;;
RYF)
    TRACK_ID=28
    ;;
RGV2)
    TRACK_ID=17
    ;;
RMR)
    TRACK_ID=21
    ;;
RSL)
    TRACK_ID=20
    ;;
RSGB)
    TRACK_ID=16
    ;;
RDS)
    TRACK_ID=31
    ;;
RWS)
    TRACK_ID=26
    ;;
RDH)
    TRACK_ID=29
    ;;
RBC3)
    TRACK_ID=19
    ;;
RDKJP)
    TRACK_ID=22
    ;;
RMC)
    TRACK_ID=25
    ;;
RMC3)
    TRACK_ID=18
    ;;
RPG)
    TRACK_ID=30
    ;;
RDKM)
    TRACK_ID=27
    ;;
RBC)
    TRACK_ID=23
    ;;
*)
    echo "$PROGNAME: invalid track '$TRACK'"
    exit 1
    ;;
esac

echo Track ID: $TRACK_ID

test -d "$WIISCRUB_DIR/../Ghosts" || mkdir "$WIISCRUB_DIR/../Ghosts"

if test -n "$FILE"; then
    cp "$FILE" "$WIISCRUB_DIR/../Ghosts/ghost1_comp_$TRACK_ID"
    cp "$FILE" "$WIISCRUB_DIR/../Ghosts/ghost2_comp_$TRACK_ID"
else
    cp "$GHOST_DIR/*.rkg" "$WIISCRUB_DIR/../Ghosts/ghost1_comp_$TRACK_ID"
    cp "$GHOST_DIR/*.rkg" "$WIISCRUB_DIR/../Ghosts/ghost2_comp_$TRACK_ID"
fi

cd "$WIISCRUB_DIR" || exit 1
wine WIIScrubber.exe || exit 4
