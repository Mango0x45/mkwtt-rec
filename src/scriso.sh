#!/usr/bin/env sh

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~ Automatically rename .rkg files for easy scrubbing ~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

GHOST_DIR="$HOME/Downloads"
WIISCRUB_DIR="$HOME/Documents/MKWRecording/Ghosts"

if test -n "$1"
then
    TRACK=$1
else
    printf "Track: "
    read -r TRACK
fi

case $TRACK in
    "LC" )
        TRACK_ID='00' ;;
    "MMM" )
        TRACK_ID='01' ;;
    "MG" )
        TRACK_ID='02' ;;
    "TF" )
        TRACK_ID='03' ;;
    "MC" )
        TRACK_ID='04' ;;
    "CM" )
        TRACK_ID='05' ;;
    "DKSC"|"DKS" )
        TRACK_ID='06' ;;
    "WGM" )
        TRACK_ID='07' ;;
    "DC" )
        TRACK_ID='08' ;;
    "KC" )
        TRACK_ID='09' ;;
    "MT" )
        TRACK_ID='11' ;;
    "GV" )
        TRACK_ID='10' ;;
    "DDR" )
        TRACK_ID='13' ;;
    "MH" )
        TRACK_ID='12' ;;
    "BC" )
        TRACK_ID='14' ;;
    "RR" )
        TRACK_ID='15' ;;
    "rPB" )
        TRACK_ID='24' ;;
    "rYF" )
        TRACK_ID='28' ;;
    "rGV2" )
        TRACK_ID='17' ;;
    "rMR" )
        TRACK_ID='21' ;;
    "rSL" )
        TRACK_ID='20' ;;
    "rSGB" )
        TRACK_ID='16' ;;
    "rDS" )
        TRACK_ID='31' ;;
    "rWS" )
        TRACK_ID='26' ;;
    "rDH" )
        TRACK_ID='29' ;;
    "rBC3" )
        TRACK_ID='19' ;;
    "rDKJP" )
        TRACK_ID='22' ;;
    "rMC" )
        TRACK_ID='25' ;;
    "rMC3" )
        TRACK_ID='18' ;;
    "rPG" )
        TRACK_ID='30' ;;
    "rDKM" )
        TRACK_ID='27' ;;
    "rBC" )
        TRACK_ID='23' ;;
    * )
        echo Invalid track
        exit 1 ;;
esac

echo Track ID: $TRACK_ID

cp "$GHOST_DIR/*.rkg" "$WIISCRUB_DIR/ghost1_comp_$TRACK_ID"
cp "$GHOST_DIR/*.rkg" "$WIISCRUB_DIR/ghost2_comp_$TRACK_ID"

cd "$WIISCRUB_DIR" || exit 1
wine WIIScrubber.exe
