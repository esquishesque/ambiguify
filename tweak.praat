
input_directory$ = "temp_output/"
output_directory$ = "output/"
file_name$ = "tweak_times"
file_extension$ = ".txt"

Read Strings from raw text file... 'input_directory$''file_name$''file_extension$'
numberOfLines = Get number of strings
for iline to numberOfLines
	select Strings 'file_name$'
	word$ = Get string... iline
	iline = iline + 1
	cut_start$ = Get string... iline
	cut_start = number (cut_start$)
	iline = iline + 1
	cut_end$ = Get string... iline
	cut_end = number (cut_end$)
	
	Read from file... 'input_directory$''word$'.wav
	Extract part... 0 'cut_start' rectangular 1.0 0
	Rename... part1
	select Sound 'word$'
	total_duration = Get end time
	Extract part... 'cut_end' 'total_duration' rectangular 1.0 0
	Rename... part2
	select Sound part1
	plus Sound part2
	Concatenate
	Scale intensity... 55
	Save as WAV file... 'output_directory$''word$'.wav

	select all
	minus Strings 'file_name$'
	Remove
endfor

select all
Remove
