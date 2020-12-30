#!/bin/sh

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~ Concatinate video files ~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~

test -z "$1" && echo "Usage: vidconcat [FILE]" && exit 1

if test "$1" = "-a"
then
    # Get an audio file for each video file
    for VIDEO in *.avi
    do
        AUDIO="$(echo "$VIDEO" | cut -d '.' -f 1).wav"
        test -e "$VIDEO" || exit 1
        ffmpeg -i "$VIDEO" -c copy "$AUDIO"
    done

    # Overlay the custom BGM on the run's audio file
    ffmpeg -y -i run.wav -i bgm.wav -filter_complex amix=inputs=2:duration=shortest run2.wav
    mv run2.wav run.wav

    # Stick 'em all together
    sed 's/.avi/.wav/g' concat.txt > aconcat.txt
    ffmpeg -f concat -safe 0 -i "$2" -an -c copy concat.avi
    ffmpeg -f concat -safe 0 -i "aconcat.txt" -c copy concat.wav
    ffmpeg -i concat.avi -i concat.wav -c copy output.avi

    # Cleanup
    rm aconcat.txt concat.avi ./*.wav
else
    ffmpeg -f concat -safe 0 -i "$1" -c copy output.avi
fi
