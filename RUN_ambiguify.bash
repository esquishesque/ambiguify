#!usr/bin/bash
scale=$1
vot=$2
vow=$3

#prep output folders
mkdir output
mkdir temp_output

#create output file and run ambiguify praat script
touch output/praat_output.tsv
mv output/praat_output.tsv ./
/Applications/Praat.app/Contents/MacOS/Praat --run ambiguify.praat $scale $vot $vow
mv seam_measurements.csv temp_output/
mv praat_output.tsv output/

#create output file and run R script
touch temp_output/tweak_times.txt
Rscript calculate_tweak.R

#run final praat script
/Applications/Praat.app/Contents/MacOS/Praat --run tweak.praat

#trash the temporary files
rm temp_output/seam_measurements.csv
rm temp_output/tweak_times.txt
mv temp_output/* ~/.Trash/
rmdir temp_output
