#!/bin/bash

export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

set +u
set -e
#set -x

#echo -e "$0 Parameter: $*"

declare -r RED_BEG="\\033[31m"
declare -r PUR_BEG="\\033[35m"
declare -r GREEN_BEG="\\033[32m"
declare -r BLUE_BEG="\\033[34m"
declare -r TUERK_BEG="\\033[34m"
declare -r COL_END="\\033[0m"
declare -r UNDERLINE="\\033[4m"

declare ARG_OPTION=$1

set -u

#>>==========================================================================>>
# DESCRIPTION:  Checked if the needed tools are on the console
#
# PARAMETER 1:  Checked if the needed tools are on the console
# RETURN:       -
# USAGE:        needed_tools
#
# AUTHOR:       TT
# REVIEWER(S):  -
#<<==========================================================================<<
needed_tools() { #Validate if the needed tool are on the shell

	declare -ra TOOLS=(wget gunzip dd md5sum truncate)

	for X in ${TOOLS[*]}; do
		if ! which $X >/dev/null 2>/dev/null; then
			error_trace "$X is not on your device"
			help_trace "Please install $X"
			exit
		fi
	done

}

#>>==========================================================================>>
# DESCRIPTION:  Download the Image File from the Internet
#
# PARAMETER 1:  Download the Image File from the Internet
# PARAMETER 2:  If the Image file a .gz file, the script try to unpack the file
# RETURN:       -
# USAGE:        download
#
# AUTHOR:       TT
# REVIEWER(S):  -
#<<==========================================================================<<
download() { #Download the Software and unpack them, if required
	head_trace "download process and verifikation"
	info_trace "Download the Software"
	if ! wget -c $LINK; then
		error_trace "Maybe the URL is not available or the URL ist passed off "
		help
		exit
	fi
	download_verifikation
	info_trace "Try to unpack the downloaded Software"
	if ! gunzip $FILENAME >/dev/null 2>/dev/null; then
		unpack_text
	fi
}

#>>==========================================================================>>
# DESCRIPTION:  Checked the checkvalue from the Image-file and the real checkvalue with each other
#
# PARAMETER 1:  Checked the checkvalue from the Image-file and the real checkvalue with each other
# PARAMETER 2:  Are the checkvalues the same, the script continues working
# PARAMETER 3:  Are the checkvalues different, the script stop
# RETURN:       -
# USAGE:        download_verifikation
#
# AUTHOR:       TT
# REVIEWER(S):  -
#<<==========================================================================<<
download_verifikation() {

	if [ $CHECKVALUE ]; then
		download_verifikation_p_text
	else
		echo -e "Please enter a check value methodik"
		read -p "md5sum, sha256, I dont have a check value [m,s,a]:" CHECK
	fi

	case $CHECK in
	m | md | M | MD | md5sum | MD5SUM)
		download_checksum_p_text
		declare -r MD_FILE=$(md5sum $FILENAME | cut -d" " -f1)
		info_trace "Compare the check value from the Image-file and the real checkvalue with each other"

		if [ $MD_FILE == $VALUE ]; then
			download_verifikation_text
		else
			download_verifikation_text2
		fi
		;;

	s | S | Sha | sha | SHA | sha256 | SHA256 | 256)
		download_checksum_p_text
		declare MAC_SUPPORT=$(sw_vers 2>/dev/null | grep ProductName | awk '{print $2}')
		info_trace "Compare the check value from the Image-file and the real checkvalue with each other"

		if [ $MAC_SUPPORT = Mac ] 2>/dev/null; then
			declare -r SH_FILE=$(shasum -a 256 $FILENAME 2>/dev/null | cut -d" " -f1)
		else
			declare -r SH_FILE=$(sha256sum $FILENAME 2>/dev/null | cut -d" " -f1)
		fi

		if [ $SH_FILE == $VALUE ]; then
			download_verifikation_text
		else
			download_verifikation_text2
		fi

		;;

	a | A) ;;

	*)

		error_trace "Wrong Answer"
		help_trace "Try it again"
		exit
		;;

	esac
}

#>>==========================================================================>>
# DESCRIPTION:  Checked if a value is given
#
# PARAMETER 1:  Checked if a value is given
# RETURN:       -
# USAGE:        download_verifikation
#
# AUTHOR:       TT
# REVIEWER(S):  -
#<<==========================================================================<<
download_verifikation_p_text() {
	if [ $CHECKVALUESUM = 32 ]; then
		declare -g CHECK=m
	elif [ $CHECKVALUESUM = 64 ]; then
		declare -g CHECK=s
	else
		echo -e "Please enter a check value methodik"
		read -p "md5sum, sha256, I dont have a check value [m,s,a]:" CHECK
	fi
}

#>>==========================================================================>>
# DESCRIPTION:  Doesn't exist the variable, the script ask for the checkvalue
#
# PARAMETER 1:  Doesn't exist the variable, the script ask for the checkvalue
# RETURN:       -
# USAGE:        download_verifikation
#
# AUTHOR:       TT
# REVIEWER(S):  -
#<<==========================================================================<<
download_checksum_p_text() {
	if [ $CHECKVALUESUM ]; then
		echo
	else
		read -p "Now enter the Check value number:" VALUE
	fi
}

#>>==========================================================================>>
# DESCRIPTION:  Text for the download_verifikation function, if the hashvalues are rigth
#
# PARAMETER 1:  Text, if the hashvalues are correct by the download_verifikation function
# RETURN:       -
# USAGE:        download_verifikation
#
# AUTHOR:       TT
# REVIEWER(S):  -
#<<==========================================================================<<
download_verifikation_text() {
	correct_trace "Hash values are the same"
	correct_trace "Verifikation successfull"
}

#>>==========================================================================>>
# DESCRIPTION:  Error Text for the download_verifikation function
#
# PARAMETER 1:  Text, if the hashvalues are correct by the download_verifikation function
# RETURN:       -
# USAGE:        download_verifikation
#
# AUTHOR:       TT
# REVIEWER(S):  -
#<<==========================================================================<<
download_verifikation_text2() {
	error_trace "Hash values are not the same"
	help_trace "Faulty image file"
	help_trace "Please start a new Download"
	help_trace "Verifikation Unsuccessfully"
	rm $FILENAME
	exit
}

#>>==========================================================================>>
# DESCRIPTION:  Copy doesen't gone with all function
#
# PARAMETER 1:  Doesn't exist the file, the script breaks off
# PARAMETER 2:  When the file is adirectory, the script breaks off
# RETURN:       -
# USAGE:        copy_specification
#
# AUTHOR:       TT
# REVIEWER(S):  -
#<<==========================================================================<<
copy_specification() {
	if ! [ -e $FILENAME ]; then
		error_trace "File doesn't exist"
		exit
	fi

	if [ -d $FILENAME ]; then
		error_trace "You cant copy a directory"
		exit
	fi
}

#>>==========================================================================>>
# DESCRIPTION:  unpack a .gz image-file
#
# PARAMETER 1:  unpack a .gz image-file
# RETURN:       -
# USAGE:        unpack
#
# AUTHOR:       TT
# REVIEWER(S):  -
#<<==========================================================================<<
unpack() { #Unpack the Software
	head_trace "Unpack process"
	info_trace "Unpack the Software"
	if ! gunzip $FILENAME >/dev/null 2>/dev/null; then
		unpack_text
		exit
	fi
}

#>>==========================================================================>>
# DESCRIPTION:  Is the text for the unpack or download function
#
# PARAMETER 1:  Is the text for the unpack or download function
# RETURN:       -
# USAGE:        unpack, download
#
# AUTHOR:       TT
# REVIEWER(S):  -
#<<==========================================================================<<
unpack_text() { #Text for the unpack part
	echo -e "Unpack is not required"
}

#>>==========================================================================>>
# DESCRIPTION:  Help text for a invalid command
#
# PARAMETER 1:  Show a help text for a invalid command
# RETURN:       -
# USAGE:        help
#
# AUTHOR:       TT
# REVIEWER(S):  -
#<<==========================================================================<<
help() { #Is a help text
	echo -e "invalid command"
	echo -e "Call: ./image_to_device.sh [-d, --download, -g, --gunzip, -c, --copy ] [Downloadlink, File to unpack, File to copy ]"
	echo -e "Example: ./imagizor.sh -d http://download.opensuse.org/distribution/leap/42.3/iso/openSUSE-Leap-42.3-DVD-x86_64.iso.sha256"
	echo -e "Check value for sha256: 47c0da3e35cce827e2e0715aba82616430f46b78"
	exit
}

#>>==========================================================================>>
# DESCRIPTION:  When less then 2 parameter are given, the script show a help text
#
# PARAMETER 1:  When less then 2 parameter are given, the script show a help text
# RETURN:       -
# USAGE:        parameter_show
#
# AUTHOR:       TT
# REVIEWER(S):  -
#<<==========================================================================<<
parameter_show() { #Checked if more then 2 Parameter are given
	if [ $# -lt 2 ]; then
		help_for_less_Parameter
	fi
}

#>>==========================================================================>>
# DESCRIPTION:  Help text for the parameter_show function
#
# PARAMETER 1:  Help text for the parameter_show function
# RETURN:       -
# USAGE:        parameter_show
#
# AUTHOR:       TT
# REVIEWER(S):  -
#<<==========================================================================<<
help_for_less_Parameter() { #Longer help text
	echo -e "Call: ./image_to_device.sh [-d, --download, -g, --gunzip] [Downloadlink, File to unpack]"
	echo -e "./image_to_device.sh                    -g      --gunzip                            File to unpack"
	echo -e "./image_to_device.sh                    -d      --download                          Downloadlink"
	echo -e "./image_to_device.sh                    -c      --copy                              File to copy"
	echo -e "Example: ./imagizor.sh -d http://download.opensuse.org/distribution/leap/42.3/iso/openSUSE-Leap-42.3-DVD-x86_64.iso.sha256"
	echo -e "Check value for sha256: 47c0da3e35cce827e2e0715aba82616430f46b78"
	exit
}

#>>==========================================================================>>
# DESCRIPTION:  Checked if the USB-Stick or the SD-Card is available
#
# PARAMETER 1:  Checked if the USB-Stick or the SD-Card is available
# PARAMETER 2:  Is the device not available, the script searched until the device is available
# RETURN:       -
# USAGE:        detect_device
#
# AUTHOR:       TT
# REVIEWER(S):  -
#<<==========================================================================<<
detect_device() { #Checked if the USb-Stick or SD-Card available
	head_trace "Find out the $DEVICE_TEXT"
	info_trace "Checked if the $DEVICE_TEXT exists"

	if ! [ -b $DEVICE ]; then
		error_trace "$DEVICE_TEXT is not available"
		help_trace "Please put a $DEVICE_TEXT in"
		help_trace "At least $FILESIZE are needed"
	fi
	while true; do
		sleep 1
		if [ $MAC_SUPPORT = Mac ] 2>/dev/null; then
			declare SIZE=$(diskutil info $DEVICE 2>/dev/null | grep 'Disk Size' | awk '{print $3}')
		else
			declare SIZE=$(lsblk $DEVICE 2>/dev/null | grep "$DEVICE_GREP" | awk '{print $4}')
		fi

		if [ -b $DEVICE ]; then
			size_trace "The $DEVICE_TEXT is $SIZE big"
			break
		fi
	done
}

#>>==========================================================================>>
# DESCRIPTION:  Checked if the Size of the Device is bigger then the Size of the Image file
#
# PARAMETER 1:  Checked if the Size of the Device is bigger then the Size of the Image file
# PARAMETER 2:  Is the Size of the Device smaller, trhe Script wait until more memory on the Device is
# RETURN:       -
# USAGE:        checked_device_and_filesize
#
# AUTHOR:       TT
# REVIEWER(S):  -
#<<==========================================================================<<
checked_device_and_filesize() { #Checked the Sd-Card Size and the filesize
	head_trace "Checking Size"
	info_trace "Checked the Size of the $DEVICE_TEXT and the Image-File"
	if [ $SIZE_WHOLE -lt $FILESIZE_WHOLE ] >/dev/null 2>/dev/null; then
		error_trace "$DEVICE_TEXT has less memory space"
		help_trace "Please put a new $DEVICE_TEXT in"
		help_trace "Or provide more memory Space"
		help_trace "At least $FILESIZE are needed"
	fi
	while true; do
		sleep 1
		if [ $MAC_SUPPORT = Mac ] 2>/dev/null; then
			declare SIZE_WHOLE=$(diskutil info $DEVICE 2>/dev/null | grep 'Disk Size' | awk '{print $5}' | cut -b 2-11)
		else
			declare SIZE_WHOLE=$(lsblk -b $DEVICE | grep "$DEVICE_GREP" | awk '{print $4}')
		fi

		if [ $SIZE_WHOLE -gt $FILESIZE_WHOLE ] >/dev/null 2>/dev/null; then
			correct_trace "$DEVICE_TEXT is bigger then the Image-File "
			break
		fi
	done
}

#>>==========================================================================>>
# DESCRIPTION:  Copy the Image-file on a USB-Stick or SD-Card
#
# PARAMETER 1:  Copy the Image-file on a USB-Stick or SD-Card
# RETURN:       -
# USAGE:        copy
#
# AUTHOR:       TT
# REVIEWER(S):  -
#<<==========================================================================<<
copy() { #copy the File on the DEVICE
	head_trace "Copy process"
	info_trace "Copy the File on the $DEVICE_TEXT"
	declare -r BLOCKS=8000000
	set +e
	sudo dd if=$FILENAME of=$DEVICE $DD_CONV bs=$BLOCKS count=$((FILESIZE_WHOLE)) $STATUS
	not_available_device
	set -e
}

#>>==========================================================================>>
# DESCRIPTION:  Copy the File from a USB-Stick or SD-Card to a File
#
# PARAMETER 1:  Copy the File from a USB-Stick or SD-Card to a File
# PARAMETER 2:  Shorten the Returned Filesize to the original Size
# RETURN:       -
# USAGE:        copy_back
#
# AUTHOR:       TT
# REVIEWER(S):  -
#<<==========================================================================<<
copy_back() { #Copy the File from the SD-Card or USB-STick back into an File
	head_trace "Verifying"
	info_trace "Copy the File from the $DEVICE_TEXT back into an File"
	declare -r BLOCKS_BACK=1000000
	set +e
	sudo dd if=$DEVICE of=verify.img $DD_CONV bs=$BLOCKS_BACK count=$((FILESIZE_WHOLE)) $STATUS
	not_available_device
	set -e
	info_trace "Shortening the returned File in the Size from the original File"
	sudo truncate -r $FILENAME verify.img
}

#>>==========================================================================>>
# DESCRIPTION:  Checked the Size of the Image-file
#
# PARAMETER 1:  Checked the Size of the Image-file
# RETURN:       -
# USAGE:        filesize
#
# AUTHOR:       TT
# REVIEWER(S):  -
#<<==========================================================================<<
filesize() { #Checked the Filesize
	head_trace "Size checking"
	info_trace "Checked the Filesize of the Image-File"
	size_trace "Filesize of the Image-File: $FILESIZE"
}

#>>==========================================================================>>
# DESCRIPTION:  Compare the hash values from the downloaded File and the returned File
#
# PARAMETER 1:  Compare the hash values from the downloaded File and the returned File
# PARAMETER 2:  Are the hash values the same the verifying is Successfully
# PARAMETER 3:  Are the hash values not the same the verifying is Unsuccessfully
# RETURN:       -
# USAGE:        compare_hash_values
#
# AUTHOR:       TT
# REVIEWER(S):  -
#<<==========================================================================<<
compare_hash_values() { #Compares the hash values from the downloaded File and the returned File
	info_trace "Compare the hash values from the downloaded File and the returned File"
	declare -r MD5SUM=$(md5sum $FILENAME | cut -d" " -f1)
	declare -r MD5SUM_BACK=$(md5sum verify.img | cut -d" " -f1)
	if [ $MD5SUM == $MD5SUM_BACK ]; then
		correct_trace "The hash values are right"
		correct_trace "Successfully Verifying "
	else
		error_trace "The hash values are not right, please try it again"
		error_trace "Unsuccessfully verifying"
		exit
	fi
}

#>>==========================================================================>>
# DESCRIPTION:  Checked if the Device during the copy process present
#
# PARAMETER 1:  Checked if the Device during the copy process present
# RETURN:       -
# USAGE:        copy, copy_back
#
# AUTHOR:       TT
# REVIEWER(S):  -
#<<==========================================================================<<
not_available_device() {
	if ! [ -e $DEVICE ]; then
		error_trace "$DEVICE_TEXT is not available"
		help_trace "Please try it again"
		exit
	fi
}

#>>==========================================================================>>
# DESCRIPTION:  Delete the returned file
#
# PARAMETER 1:  Delete the returned file
# RETURN:       -
# USAGE:        delete_returned_file
#
# AUTHOR:       TT
# REVIEWER(S):  -
#<<==========================================================================<<
delete_returned_file() { #Delete the returned File
	rm -rf verify.img
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

#>>==========================================================================>>
# DESCRIPTION:  Marked the echo text red
#
# PARAMETER 1:  Marked the echo text red
# RETURN:       -
# USAGE:        help_trace "Text"
#
# AUTHOR:       TT
# REVIEWER(S):  -
#<<==========================================================================<<
help_trace() { #marked RED
	echo -e "${RED_BEG}$1${COL_END}"
}

#>>==========================================================================>>
# DESCRIPTION:  Marked the echo text red and added an ERROR at the begining
#
# PARAMETER 1:  Marked the echo text red and added an ERROR at the begining
# RETURN:       -
# USAGE:        error_trace "Text"
#
# AUTHOR:       TT
# REVIEWER(S):  -
#<<==========================================================================<<
error_trace() { #marked RED and added an ERROR at the begining
	echo -e "\n${RED_BEG}ERROR: $1${COL_END}"
}

#>>==========================================================================>>
# DESCRIPTION:  Marked the echo text green
#
# PARAMETER 1:  Marked the echo text green
# RETURN:       -
# USAGE:        correct_trace "Text"
#
# AUTHOR:       TT
# REVIEWER(S):  -
#<<==========================================================================<<
correct_trace() { #marked Green
	echo -e "${GREEN_BEG}$1${COL_END}"
}

#>>==========================================================================>>
# DESCRIPTION:  Marked the echo text blue
#
# PARAMETER 1:  Marked the echo text blue
# RETURN:       -
# USAGE:        size_trace "Text"
#
# AUTHOR:       TT
# REVIEWER(S):  -
#<<==========================================================================<<
size_trace() { #marked Blue
	echo -e "${BLUE_BEG}$1${COL_END}"
}

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

read_p_text() {
	echo -e "Do you want to copy on the SD-Card or on the USB-Stick?"
	read -p "SD-Card,USB-Stick [S,U]:" ANSWER
}

#>>==========================================================================>>
# DESCRIPTION:  Declare important variables for the script
#
# PARAMETER 1:  Declare variables fo the Script
# RETURN:       -
# USAGE:        variable
#
# AUTHOR:       TT
# REVIEWER(S):  -
#<<==========================================================================<<
variable() {
	if [ $MAC_SUPPORT = Mac ] 2>/dev/null; then
		declare DEVICE=""
	else
		declare -g DEVICE=$DEVICE_LINUX
		declare -g SIZE=$(lsblk $DEVICE 2>/dev/null | grep "$DEVICE_GREP" | awk '{print $4}')
		declare -g FILESIZE_WHOLE=$(stat -c %s $FILENAME 2>/dev/null)
		declare -g STATUS="status=progress"
		declare -g DD_CONV="conv=fdatasync"
	fi
}

if [ $# -lt 2 ]; then #in the case they are less then 2 Parameter are given, then spend a text
	help_for_less_Parameter
	exit
fi

trap delete_returned_file exit
trap delete_returned_file term

declare -r LINK=$2
declare FILENAME="$(basename $2)"

if [ $# -gt 2 ]; then
    declare CHECKVALUE=$3
    declare CHECKVALUESUM="$(expr length $3)"
    declare VALUE=$3
else
    declare CHECKVALUE=""
    declare CHECKVALUESUM=""
    declare VALUE=""
fi

declare MAC_SUPPORT=$(sw_vers 2>/dev/null | grep ProductName | awk '{print $2}')

needed_tools

case $ARG_OPTION in
"-d")
	download
	;;

"--download")
	download
	;;

"-g")
	unpack
	;;

"--gunzip")
	unpack
	;;
"-c")
	copy_specification
	;;

"--copy")
	copy_specification
	;;

"--help")
	help_for_less_Parameter
	;;

"*")
	help
	exit
	;;
esac

declare FILESIZE=$(du -h $FILENAME | awk '{print $1}')
declare SIZE=""
declare SIZE_WHOLE=""
declare MAC_SUPPORT=$(sw_vers 2>/dev/null | grep ProductName | awk '{print $2}')
declare DD_CONV=""

if [ $MAC_SUPPORT = Mac ] 2>/dev/null; then
	head_trace "Only use one SD-Card or USB-Stick for your device!"
else
	declare DEVICE=""
fi

if [ $# -gt 3 ]; then
	declare ANSWER=$4
else
	read_p_text
fi

case "$ANSWER" in
USB | USB-Stick | Usb-Stick | usb-stick | Usb | usb | u | U)

	declare -r DEVICE_LINUX=/dev/sdb 2>/dev/null
	declare DEVICE=/dev/disk2
	declare SIZE_WHOLE=$(diskutil info /dev/disk2 2>/dev/null | grep 'Disk Size' | awk '{print $5}' | cut -b 2-11)
	declare FILESIZE_WHOLE=$(stat -l $FILENAME 2>/dev/null | awk '{print $5}')
	declare -r DEVICE_TEXT="USB-Stick"
	declare -r DEVICE_GREP="sdb "
	declare STATUS=""

	variable

	detect_device

	checked_device_and_filesize

	filesize

	copy

	copy_back

	compare_hash_values

	info_trace "Delete the returned File"

	delete_returned_file

	correct_trace "You can remove the USB-Stick"
	;;

SD-Card | Sd-Card | sd-Card | sd-card | SD | Sd | sd | S | s)

	if [ -e /dev/sde ]; then
		declare -r DEVICE_LINUX=/dev/sde 2>/dev/null
		declare DEVICE_GREP="sde "
	else
		declare -r DEVICE_LINUX=/dev/mmcblk0 2>/dev/null
		declare -r DEVICE_GREP="mmcblk0 "
	fi

	declare FILESIZE_WHOLE=$(stat -l $FILENAME 2>/dev/null | awk '{print $5}')
	declare -r DEVICE_TEXT="SD-Card"
	declare STATUS=""

	if [ -e /dev/disk2 ]; then
		declare DEVICE=/dev/disk2
		declare SIZE_WHOLE=$(diskutil info /dev/disk2 2>/dev/null | grep 'Disk Size' | awk '{print $5}' | cut -b 2-11)
	else
		declare DEVICE=/dev/disk3
		declare SIZE_WHOLE=$(diskutil info /dev/disk3 2>/dev/null | grep 'Disk Size' | awk '{print $5}' | cut -b 2-11)
	fi

	variable

	detect_device

	checked_device_and_filesize

	filesize

	copy

	copy_back

	compare_hash_values

	info_trace "Delete the returned File"

	delete_returned_file

	correct_trace "You can remove the Sd-Card"
	;;
*)
	error_trace "Wrong answer"
	help_trace "Please try it again"
	exit
	;;
esac
