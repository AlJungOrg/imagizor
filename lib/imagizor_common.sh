
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
	echo -e ----------------------------------------------------------------------
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
