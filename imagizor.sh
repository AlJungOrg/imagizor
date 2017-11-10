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

needed_tools() { #Validate if the needed tool are on the shell
	
	tools=(wget gunzip dg md5sum truncate)

	if ! which ${tools[*]} 2&>/dev/null; then
        echo "is not available"
    fi
}

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

download_verifikation() {
	echo -e "Please enter a check value methodik"
	read -p "mdsum, sha256, I dont have a checkvalue [m,s,a]:" CHECK

	case $CHECK in
	m | md | M | MD | md5sum | MD5SUM)
		read -p "Now enter the Check value number:" VALUE
		declare -r MD_FILE=$(md5sum $FILENAME | cut -d" " -f1)

		if [ $MD_FILE == $VALUE ]; then
			correct_trace "Hash values are the same"
			correct_trace "Verifikation successfull"
		else
			error_trace "Hash values are not the same"
			help_trace "Ples try it again"
			help_trace "Verifikation Unsuccessfully"
			exit
		fi
		;;

	s | S | Sha | sha | SHA | sha256 | SHA256 | 256)
		read -p "Now enter the Check value number:" VALUE
		declare MAC_SUPPORT=$(sw_vers 2>/dev/null | grep ProductName | awk '{print $2}')
		if [ $MAC_SUPPORT = Mac ] 2>/dev/null; then
			declare -r SH_FILE=$(shasum -a 256 $FILENAME 2>/dev/null | cut -d" " -f1)
		else
			declare -r SH_FILE=$(sha256sum $FILENAME 2>/dev/null | cut -d" " -f1)
		fi

		if [ $SH_FILE == $VALUE ]; then
			correct_trace "Hash values are the same"
			correct_trace "Verifikation successfull"
		else
			error_trace "Hash values are not the same"
			help_trace "Ples try it again"
			help_trace "Verifikation Unsuccessfully"
			exit
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

unpack() { #Unpack the Software
	head_trace "Unpack process"
	info_trace "Unpack the Software"
	if ! gunzip $FILENAME >/dev/null 2>/dev/null; then
		unpack_text
		exit
	fi
}

unpack_text() { #Text for the unpack part
	echo -e "Unpack is not required"
}

help() { #Is a help text
	echo -e "invalid command"
	echo -e "Call: ./image_to_device.sh [-d, --download, -g, --gunzip] [Downloadlink, File to unpack]"
	echo -e "Example: ./imagizor.sh -d http://download.opensuse.org/distribution/leap/42.3/iso/openSUSE-Leap-42.3-DVD-x86_64.iso.sha256"
	exit
}

parameter_show() { #Checked if more then 2 Parameter are given
	if [ $# -lt 2 ]; then
		help_for_less_Parameter
	fi
}

help_for_less_Parameter() { #Longer help text
	echo -e "Call: ./image_to_device.sh [-d, --download, -g, --gunzip] [Downloadlink, File to unpack]"
	echo -e "./image_to_device.sh                    -g      --gunzip                            File to unpack"
	echo -e "./image_to_device.sh                    -d      --download                          Downloadlink"
	echo -e "Example: ./imagizor.sh -d http://download.opensuse.org/distribution/leap/42.3/iso/openSUSE-Leap-42.3-DVD-x86_64.iso.sha256"
	exit
}

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

checked_fevice_and_filesize() { #Checked the Sd-Card Size and the filesize
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

copy() { #copy the File on the DEVICE
	head_trace "Copy process"
	info_trace "Copy the File on the $DEVICE_TEXT"
	declare -r BLOCKS=8000000
	set +e
	sudo dd if=$FILENAME of=$DEVICE $DD_CONV bs=$BLOCKS count=$((FILESIZE_WHOLE)) $STATUS
	not_available_device
	set -e
}

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

filesize() { #Checked the Filesize
	head_trace "Size checking"
	info_trace "Checked the Filesize of the Image-File"
	size_trace "Filesize of the Image-File: $FILESIZE"
}

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
	fi
}

not_available_device() {
	if ! [ -e $DEVICE ]; then
		error_trace "$DEVICE_TEXT is not available"
		help_trace "Please try it again"
		exit
	fi
}

delete_returned_file() { #Delete the returned File
	rm -rf verify.img
}

info_trace() { #marked purple
	echo -e "${PUR_BEG}$1${COL_END}"
}

help_trace() { #marked RED
	echo -e "${RED_BEG}$1${COL_END}"
}

error_trace() { #marked RED and added an ERROR at the begining
	echo -e "\n${RED_BEG}ERROR: $1${COL_END}"
}

correct_trace() { #marked Green
	echo -e "${GREEN_BEG}$1${COL_END}"
}

size_trace() { #marked Blue
	echo -e "${BLUE_BEG}$1${COL_END}"
}

head_trace() { #create a underline and the text is purple
	echo -e ______________________________________________________________________
	echo -e "\n${UNDERLINE}${PUR_BEG}$1${COL_END}\n"
	echo -e ----------------------------------------------------------------------
}

read_p_text() {
	echo -e "Do you want to copy on the SD-Card or on the USB-Stick?"
	read -p "SD-Card,USB-Stick [S,U]:" ANSWER
}

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
declare -r FILENAME="$(basename $2)"

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

read_p_text

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

	checked_fevice_and_filesize

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

	checked_fevice_and_filesize

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
