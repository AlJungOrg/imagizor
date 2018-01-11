
#!/bin/bash

#>>==========================================================================>>
# DESCRIPTION:  Marked the echo text purple and create a undeline
#
# PARAMETER 1:  Marked the echo text purple and create a undeline
# RETURN:       -
# USAGE:        head_trace "Text"
#
# AUTHOR:       TT
# REVIEWER(S):  -
#<<==========================================================================<<
head_trace() { #create a underline and the text is purple
	echo -e ______________________________________________________________________
	echo -e "\n${UNDERLINE}${PUR_BEG}$1${COL_END}\n"
	echo -e ""
}

head_trace_end() {
    echo -e ______________________________________________________________________
}

#>>==========================================================================>>
# DESCRIPTION:  Marked the echo text purple
#
# PARAMETER 1:  Marked the echo text purple
# RETURN:       -
# USAGE:        info_trace "Text"
#
# AUTHOR:       TT
# REVIEWER(S):  -
#<<==========================================================================<<
info_trace() { #marked purple
	echo -e "${PUR_BEG}$1${COL_END}"
}

checkstep() {
	echo -e "${PUR_BEG}$@ ...${COL_END}"
	if $@; then
		printf "%-90b %10b\n" "${PUR_BEG}$1${COL_END}" "${GREEN_BEG}OK${COL_END}"
	else
		printf "%-90b %10\n" "${PUR_BEG}$1${COL_END}" "${RED_BEG}FAIL${COL_END}"
		exit
	fi
}
