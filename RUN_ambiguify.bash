#!usr/bin/bash
scale=$1
vot=$2
vow=$3

#prep output folders
mkdir output
mkdir temp_output

#run ambiguify praat script
/Applications/Praat.app/Contents/MacOS/Praat --run ambiguify.praat $scale $vot $vow

#create output file for R script and run R script
touch temp_output/tweak_times.txt
mv seam_measurements.csv temp_output/
Rscript calculate_tweak.R

#run final praat script
/Applications/Praat.app/Contents/MacOS/Praat --run tweak.praat

#trash the temporary files
rm temp_output/seam_measurements.csv
rm temp_output/tweak_times.txt
mv temp_output/* ~/.Trash/
rmdir temp_output
