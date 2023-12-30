#written by emily clare
#this script goes through a folder of soundfiles of individual words starting with d and t.
#it creates the specified level of ambiguous stimuli between d and t,
#using the vowel of d and the onset of t, and shortening VOT and transitions incrementally.
#the resulting .wav file is saved.


form arguments
	real named_scale 65
	real named_vot 40
	real named_vow 40
endform


voiceless_letter$ = "t"
voiced_letter$ = "d"
input_directory$ = "input"
output_directory$ = "temp_output"
file_prefix$ = "amb-scale'named_scale'-vot'named_vot'-vow'named_vow'-"
seam_file$ = "seam_measurements.csv"
output_file$ = "praat_output.tsv"

scaleFactor = named_scale / 100
finvot = named_vot / 1000
ipercent = named_vow / 100

###iterate through files and open them
appendFileLine: output_file$, "word'tab$'vowdif'tab$'vowpercent'tab$'tvot'tab$'dvot'tab$'tvow'tab$'dvow"
writeFileLine: seam_file$, "word,time,value,seam,before_seam"
Create Strings as file list... list 'input_directory$'/*.wav
numberOfFiles = Get number of strings
for ifile to numberOfFiles
	select Strings list
	t_file$ = Get string... ifile
	type$ = left$ (t_file$, 1)
	if type$ = voiceless_letter$
		t_word$ = left$ ("'t_file$'", (length ("'t_file$'") -4))
		t_grid$ = replace$ ("'t_file$'", ".wav", ".TextGrid", 1)
		Read from file... 'input_directory$'/'t_file$'
		Read from file... 'input_directory$'/'t_grid$'
		d_word$ = replace$ (t_word$, voiceless_letter$, voiced_letter$, 1)		
		d_grid$ = "'d_word$'.TextGrid"
		d_file$ = replace$ (t_file$, voiceless_letter$, voiced_letter$, 1)
		path$ = "'input_directory$'/'d_word$'.wav"
		if fileReadable (path$)
			Read from file... 'path$'
			Read from file... 'input_directory$'/'d_grid$'

			###fill out textgrid times for each word
			select TextGrid 't_word$'
			temp = Get start point... 1 2
			tbeg = temp
			tpul = Get start point... 1 3
			tend = Get start point... 1 4
			temp = Get start point... 1 5
			taft = temp + 0.05
			tbef = tbeg - 0.05
			select TextGrid 'd_word$'
			temp = Get start point... 1 2
			dbeg = temp
			dpul = Get start point... 1 3
			dend = Get start point... 1 4
			temp = Get start point... 1 5
			daft = temp + 0.05
			dbef = dbeg - 0.05		
			call clean

			###set up other variables
			tvot = tpul-tbeg
			dvot = dpul-dbeg
			votdif = tvot-dvot
			tvow = tend-tpul
			dvow = dend-dpul
			vowdif = dvow-tvow
			vowpercent = vowdif/tvow

			appendFileLine: output_file$, "'t_word$''tab$''vowdif''tab$''vowpercent''tab$''tvot''tab$''dvot''tab$''tvow''tab$''dvow'"

#######################################################################
			###cutting vot
			intFile$ = "intermediateStage.wav"
			call openEdit 'input_directory$'/'t_file$'
	
			###calculate cut points
			tvotcut = tvot - finvot
			tvotcutbeg = tpul - tvotcut
			tvotcutend = tpul

			###cut and save
			newtpul = tpul-tvotcut

			###save file
			intermediatePoint = newtpul - tbef

			call saveClean 'intFile$' tbef newtpul


#######################################################################
			###cutting vow
			call openEditScale 'output_directory$'/'intFile$'

			jpercent = 1 - (ipercent)
			finvow = tvow + (jpercent*vowdif)
			call openEdit 'input_directory$'/'d_file$'

			###calculate cut points
			dvowcut = dvow - finvow
			dvowcutbeg = dpul
			dvowcutend = dpul + dvowcut

			###open file and cut and copy
			newdaft = daft - dvowcut

			Extract part... dvowcutend daft rectangular 1.0 0
#			Rename... copied_piece

			###open intermediate and paste
#			select Sound copied_piece
			plus Sound intermediateStage
			Concatenate

			###record waveform near seam
			time = intermediatePoint - 0.002
			for i to 2000
				v = Get value at time... 0 'time' Sinc70
				isSeam = abs('time' - 'intermediatePoint') < 0.00002
				beforeSeam = 'time' < 'intermediatePoint'
				appendFileLine: seam_file$, "'file_prefix$''t_word$','time','v','isSeam','beforeSeam'"
				time = time + 0.000002
			endfor

			###save file
			secondHalf = (newdaft-dpul)
			intend = intermediatePoint + secondHalf
			call saveClean 'file_prefix$''t_word$'.wav 0 intend
		endif
###end loops
	endif
endfor
select all
Remove


#####procedure find preceding zero crossing (cursor will be on it)
procedure precZero .cursor
	Move cursor to... .cursor
	Move cursor to nearest zero crossing
	zero = Get cursor
	while zero > .cursor
		.cursor = .cursor - 0.001
		Move cursor to... .cursor
		Move cursor to nearest zero crossing
		zero = Get cursor
	endwhile
endproc

#####procedure to open file
procedure open .name$
	Read from file... '.name$'
	.name$ = selected$ ("Sound")
	select Sound '.name$'
endproc

#####procedure to edit file
procedure openEditScale .name$
	Read from file... '.name$'
	.name$ = selected$ ("Sound")
	select Sound '.name$'
	Multiply... scaleFactor
endproc

#####procedure to open and edit file
procedure openEdit .name$
	Read from file... '.name$'
	.name$ = selected$ ("Sound")
	select Sound '.name$'
	Scale peak... 0.99
endproc

#####procedure to save and clean
procedure saveClean .name$ .beg .end
	Extract part... .beg .end rectangular 1.0 0
	Save as WAV file... 'output_directory$'/'.name$'
	call clean
endproc

#####procedure to clean
procedure clean
	endeditor
	select all
	minus Strings list
	Remove
endproc
