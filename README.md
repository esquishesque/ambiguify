# Overview

This script takes series of words produced with a word-initial voiced stop and their minimal pairs produced with voiceless stops (e.g. dinosaur and tinosaur, television and delevision) and generates words with an ambiguous sound between a voiced stop and a voiceless stop (e.g. ?inosaur, ?elevision).

It uses the stop+burst portion from the voiceless production (e.g. the t from tinosaur and television), cuts the aspiration to the desired amount, and makes the aspiration the desired amount quieter.  It uses the rest of the word from the voiced production (e.g. the inosaur from dinosaur and the elevision from delevision) and cuts the formant transitions the desired amount.  It then pastes these pieces together to create the ambiguous sound, while preventing any pop, click, or other noise signaling the disjoint in the files, and sets their average intensity to 55dB SPL.

# Requirements
Praat and R must be installed.  The R package "tidyverse" must be installed.

At this time, these scripts only work on MacOS, though they would work on Linux with very minimal adjustments.

# Usage
## Download
Download and unzip the repository.  That should give you a folder called ambiguify with four scripts and an input folder inside it.

## Prepare input files
Before running the script, put your input sound files and textgrids into the input folder.

The input sound files must:
  - be .wav files
  - have the same sampling rate
  - be in voiced-voiceless pairs that have identical names except one starts with "d" and one starts with "t"
    - NOTE: it is recommended to put the d and t before the word (e.g. ddinosaur.wav and tdinosaur.wav, dtelevision.wav and ttelevision.wav).
    - NOTE: the script reads the file that starts with "d" as voiced and "t" as voiceless; it works with other voiced-voiceless stop pairs (and probably with affricates and fricatives) but the filenames still need to start with d and t (e.g. if you were creating an ambiguous word between "bite" and "pite" you should name the bite file dbite.wav" and the pite file "tbite.wav")
  - have corresponding TextGrids

The input TextGrids must:
  - have the same filename as the sound files except ending in .TextGrid instead of .wav
  - have exactly 4 intervals marked on tier 1:
    - 1st interval: beginning of the word / just before the burst
    - 2nd interval: beginning of the first vowel / just after the aspiration
    - 3rd interval: end of the first vowel
    - 4th interval: end of the word (the exact placement of this one isn't so important, it only affects when the sound file ends)
  - (the labels on intervals as well as any content on other tiers is irrelevant)

## Run the script
The only script you need to run is the Bash script; it calls the others.

You will need to navigate to ambiguify in the command line.  If you don't know how to do this, open Terminal, type `cd` followed by a space, then drag the ambiguify folder from the Finder onto the Terminal window to populate the filepath.  Return to Terminal and hit enter.  You should then see `ambiguify$`.

Enter the command to run the script: `bash RUN_ambiguify.bash #1 #2 #3` but each of the three #s are parameters for creating the ambiguous file:
- #1 is the scaling of intensity applied to the aspiration, in percent (ranging from 0-100)
  - suggested start value is 65
  - the higher the number the louder the aspiration
  - a higher number will elicit more voiceless responses
- #2 is the desired vot, in ms
  - suggested start value is 40
  - the higher the number the longer the vot
  - a higher number will elicit more voiceless responses
- #3 is the amount of formant transitions to be cut, in percent of the difference between the voiced vowel duration and the voiceless vowel duration (ranging from 0-100)
  - suggested start value is 40
  - the higher the number the shorter the formant transitions
  - a higher number will elicit more voiceless responses

The script will create an output folder with the files produced by the script.

## Output
The output files will be in `ambiguify/output/`:
- all of the ambiguified .wav files
- praat_output.tsv which includes information about the durations of the VOT and vowel for the voiced and voiceless production of each word (running repeatedly will append to this output file rather than replacing it, so delete it if you're starting over)

# Precise description

This section explains exactly what the scripts do, step by step.

Starting with the voiceless production file (all done within ambiguify.praat):
- apply the "Scale peak" function with a value of 0.99 (to make the sound as loud as possible; this does a fairly good job of making the portions from the two different words compatible in terms of volume)
- grab just the stop portion of the file: starting from 50ms before the start of the word, ending at the end of the aspiration (so from interval1-0.05 to interval2)
- cut aspiration from the right edge to result in the correct output VOT (argument #2; e.g. if 40 is the output VOT and the word has 73ms VOT, the rightmost 33ms will be removed)
- apply the "Scale intensity" function to the argument provided when the script was run (argument #1)

Then with the voiced production file (all done within ambiguify.praat):
- apply the "Scale peak" function with a value of 0.99 (to make the sound as loud as possible; this does a fairly good job of making the portions from the two different words compatible in terms of volume)
- grab the rest of the word after the stop: starting from the end of the aspiration, ending 50ms after the end of the word (so from interval2 to interval4+0.05)
- cut formant transitions from the left edge to result in the correct reduction in formant transitions (argument #3; e.g. if 40, if the d production has 150ms vowel length and the t production has 100ms vowel length, the script will cut 40% of the difference between 150 and 100, so the leftmost 20ms will be removed)

Finally combine the files (done with both praat scripts and the R script):
- the goal here is to prevent any click or pop sound at the joint between the two files
- the process used here serves as an alternative to finding the nearest 0-crossing, which has flaws:
  - sometimes the nearest 0-crossing is several ms or more away
  - aspiration often has no 0-crossing at all
  - if a waveform crossing 0 on its way down is combined with a waveform crossing 0 in its way up, there is often still a click or pop sound
- first, the ambiguify.praat script creates a series of measurements of the waveform every .002ms (.000002s) for the 2ms before and the 2ms after the desired joint point, in both the voiced sound file and the voiceless sound file, using Praat's "Get value at time" function
- these measurements are read by calculate_tweak.R, which finds the best point in each file to join the files
  - it looks for places where 4 measurements in a row are heading in the same direction (upward or downward), labelling these areas stable upwards or stable downwards
  - and then it finds the timestamps to cut each file that result in the least cutting while conforming to the following requirements:
    - both files are in stable upwards or both are in stable downwards
    - the transition from the end of the first file into the start of the next file will be >0 and <0.01 and in the correct direction (e.g. if in a stable upwards period, the value of the waveform in the second file must be >0 and <0.01 higher than the value of the waveform in the first file
- these timestamps are read by tweak.praat, which cuts the files accordingly
  - it also sets the average intensity of the resulting file to 55dB SPL
