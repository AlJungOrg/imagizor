#!/bin/bash

export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

set +u
set -e
#set -x

#echo -e "$0 Parameter: $*"

. lib/imagizor_common.sh

declare TIME_START=$(date +%s)

declare -r RED_BEG="\\033[31m"
declare -r OR_BEG="\\033[33m"
declare -r PUR_BEG="\\033[35m"
declare -r GREEN_BEG="\\033[32m"
declare -r BLUE_BEG="\\033[34m"
declare -r TUERK_BEG="\\033[34m"
declare -r BOLD="\\033[1m"
declare -r BOLD_TP=$(tput bold)
declare -r TP_END=$(tput sgr0)
declare -r COL_END="\\033[0m"
declare -r UNDERLINE="\\033[4m"

declare ARG_OPTION=$1

set -u

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
	help_text_beg
	echo -e ""
	help_text_end
	exit
}

help_text_beg() {
	echo -e "Call: ./image_to_device.sh [-d, --download, -c, --copy ] [Downloadlink, File to copy ] [(optional)-t, --target] [(optional)Device (example: /dev/mmcblk0)]"
	echo -e "[(optional in download mode) -v, --value] [(optional in download mode) hashvalue (MD5SUM, SHA1, SHA256, SHA512)]"
	echo -e "[(For Authentication in download mode) -u, --user] [(For Authentication in download mode) 'USER' ('' Are needed)]"
	echo -e "[(For Authentication in download mode) -p, --password] [(For Authentication in download mode) 'PASSWORD' ('' Are needed)]"
	echo -e ""
	echo -e "./image_to_device.sh  -d  --download   'Downloadlink'  -t  --target  'Device'  -v  --value  'Checkvalue'  -u  --user  'USER'  -p  --password  'PASSWORD'"
	echo -e "./image_to_device.sh  -c  --copy       'File to copy'  -t  --target  'Device'"
	echo -e ""
	echo -e "Compatible hashvalues methodik: MD5SUM, SHA1, SHA256, SHA512"
	echo -e ""
	echo -e "explaining of the parameters:"
	echo -e '-d, --download       started the download mode'
	echo -e '-c, --copy           started the copy mode'
	echo -e '-t, --target         the device to be overwritten'
	echo -e '-v, --value          the checkvalue of the file for the download mode'
	echo -e '-u, --user           user data for the download mode for the authetifikation'
	echo -e '-p, --password       the password for the download mode for the authetifikation'
	echo -e ""
}

help_text_end() {
	echo -e "Example 1) to download a image file and write this image file to a target device (enquired during runtime), use the following command: "
	echo -e "./imagizor.sh -d http://download.opensuse.org/distribution/leap/42.3/iso/openSUSE-Leap-42.3-DVD-x86_64.iso.sha256"
	echo -e ""
	echo -e "Example 2)to verify the download process with a checkvalue and write this image file to a target device (specified with the -t option)," 
	echo -e "use the following command:"
	echo -e "./imagizor.sh -d http://download.opensuse.org/distribution/leap/42.3/iso/openSUSE-Leap-42.3-DVD-x86_64.iso.sha256 -t /dev/mmcblk0"
	echo -e "-v 1ce040ce418c6009df6e169cff47898f31c54e359b8755177fa7910730556c18"
	echo -e ""
	echo -e "Example 3)to download a file for which user data are needed and write this image file to a target device (specified with the -t option)" 
	echo -e "verify the download process with a checkvalue, use the following command:"
	echo -e "./imagizor.sh -d http://download.opensuse.org/distribution/leap/42.3/iso/openSUSE-Leap-42.3-DVD-x86_64.iso.sha256 -t /dev/mmcblk0"
	echo -e "-v 1ce040ce418c6009df6e169cff47898f31c54e359b8755177fa7910730556c18 -u 'USER' -p 'PASSWORD'"
	echo -e ""
	echo -e "Example 4) to write a locally stored image file to a target device (enquired during runtime), use the following command:"
	echo -e "./imagizor.sh -c openSUSE-Leap-42.3-DVD-x86_64.iso.sha256 "
	echo -e ""
	echo -e "Example 5) to write a locally stored image file to a target device (specified with the -t option), use the following command:"
	echo -e "./imagizor.sh -c openSUSE-Leap-42.3-DVD-x86_64.iso.sha256 -t /dev/mmcblk0"
	echo -e ""
	echo -e "Link to the GitHub Project: https://github.com/AlJungOrg/imagizor/tree/master"
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
	help_text_beg
	help_text_end
	exit
}

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

	declare -ra TOOLS=(wget gunzip dd md5sum truncate bzip2 lsblk unzip)

	for X in ${TOOLS[*]}; do
		if ! which $X >/dev/null 2>/dev/null; then
			error_trace "$X is not on your device"
			help_trace "Please install $X"
			exit
		fi
	done

}

mode_beg() {
	echo -e ""
	if [ $ARG_OPTION = -d ]; then
		echo -e "------------------------start-download-mode------------------------"
	elif [ $ARG_OPTION = --download ]; then
		echo -e "------------------------start-download-mode------------------------"
	else
		echo -e "------------------------start-copy-mode------------------------"
	fi
	echo -e ""
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
download_the_software() { #Download the Software and unpack them, if required

	if ! wget -c --auth-no-challenge --http-user=$USER --http-password="$PASSWORD" $LINK; then
		error_trace "Maybe the URL is not available or the URL is passed off "
		help
		exit
	fi
	download_verifikation
	echo -e "Try to unpack the downloaded Software"
	if ! gunzip $FILENAME >/dev/null 2>/dev/null; then
		unpack_text
	fi

	if [[ "$FILENAME" =~ ".bz2" ]]; then
		declare -g FILENAME=$(basename $2 | sed 's/.$//' | sed 's/.$//' | sed 's/.$//' | sed 's/.$//')
	elif [[ "$FILENAME" =~ ".gz" ]]; then
		declare -g FILENAME=$(basename $2 | sed 's/.$//' | sed 's/.$//' | sed 's/.$//')
    elif [[ "$FILENAME" =~ ".zip" ]]; then
        declare -g FILENAME=$(basename $2 | sed 's/.$//' | sed 's/.$//' | sed 's/.$//' | sed 's/.$//')
    elif [[ "$FILENAME" =~ ".7z" ]]; then
        declare -g FILENAME=$(basename $2 | sed 's/.$//' | sed 's/.$//' | sed 's/.$//')
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

	Parameter=($@)

	echo

	if [ $CHECKVALUE ]; then
		download_verifikation_p_text
	else
		echo -e "Please enter a check value methodik"
		bold_trace_tp "md5sum, sha256, I dont have a check value [m,s,a] (a):" CHECK
	fi

	case $CHECK in
	m | md | M | MD | md5sum | MD5SUM)
		download_checksum_p_text
		declare -r MD_FILE=$(md5sum $FILENAME | cut -d" " -f1)
		echo -e "Compareing the check value from the Image-file and the real checkvalue"

		if [ $MD_FILE == $VALUE ]; then
			download_verifikation_text
		else
			download_verifikation_text2
		fi
		;;

	s | S | Sha | sha | SHA | sha256 | SHA256 | 256)
		download_checksum_p_text
		declare MAC_SUPPORT=$(sw_vers 2>/dev/null | grep ProductName | awk '{print $2}')
		info_trace "Compareing the check value from the Image-file and the real checkvalue"

		if [ $CHECKVALUESUM = 40 ]; then
			declare -r SH_FILE=$(sha1sum $FILENAME 2>/dev/null | cut -d" " -f1)
		elif [ $CHECKVALUESUM = 64 ]; then
			declare -r SH_FILE=$(sha256sum $FILENAME 2>/dev/null | cut -d" " -f1)
		elif [ $CHECKVALUESUM = 128 ]; then
			declare -r SH_FILE=$(sha512sum $FILENAME 2>/dev/null | cut -d" " -f1)
		else
			error_trace "no valid check sum"
			exit
		fi

		if [ $SH_FILE == $VALUE ]; then
			download_verifikation_text
		else
			download_verifikation_text2
		fi

		;;

	a | A | "") ;;

	*)

		error_trace "Wrong Answer"
		help_trace "Try it again"
		exit
		;;

	esac
}

#>>==========================================================================>>
# DESCRIPTION:  Checked if the value is given
#
# PARAMETER 1:  Checked if the value is given
# RETURN:       -
# USAGE:        download_verifikation
#
# AUTHOR:       TT
# REVIEWER(S):  -
#<<==========================================================================<<
download_verifikation_p_text() {
	if [ $CHECKVALUESUM = 32 ]; then
		declare -g CHECK=m
	elif [ $CHECKVALUESUM = 40 ]; then
		declare -g CHECK=s
	elif [ $CHECKVALUESUM = 64 ]; then
		declare -g CHECK=s
	elif [ $CHECKVALUESUM = 128 ]; then
		declare -g CHECK=s
	else
		echo -e "Please enter a check value methodik"
		bold_trace_tp "md5sum, sha256, I dont have a check value [m,s,a] (a):" CHECK
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
		bold_trace_tp "Now enter the Check value number:" VALUE
		declare -g CHECKVALUESUM=$(expr length $VALUE)
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

	if [[ "$FILENAME" =~ ".bz2" ]]; then
		bzip2 -d $FILENAME
	elif [[ "$FILENAME" =~ ".gz" ]]; then
		gunzip $FILENAME
    elif [[ "$FILENAME" =~ ".zip" ]]; then
        unzip $FILENAME
	elif [[ "$FILENAME" =~ ".7z" ]]; then
        7z e $FILENAME
	fi

}

read_p_text() {
    set +u
    
	lsblk

	echo -e ""

	array=($(lsblk | grep disk | awk '{print $1}'))
	
	for ((i = 0; i < ${#array[@]}; i = i + 1)); do
		echo "$i /dev/${array[$i + 0]}"
	done

	echo ""

	if [ -b /dev/mmcblk0 ]; then
		declare AUTOMATIC=/dev/mmcblk0
	elif [ -b /dev/sdb ]; then
		declare AUTOMATIC=/dev/sdb
	else
		declare AUTOMATIC=/dev/${array[$ANSWER + 0]}
	fi

	read -p "${BOLD_TP}Please choose your device [ Enter the number for the device ] ("$AUTOMATIC"): ${TP_END}" ANSWER

	case $ANSWER in
	"")
		declare -g ANSWER=$AUTOMATIC
		;;
	esac

	re='^[0-9]+$'
	if [[ $ANSWER =~ $re ]]; then
		declare -g ANSWER=/dev/${array[$ANSWER + 0]}
	fi
	
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
		declare -g SIZE=$(lsblk $DEVICE 2>/dev/null | grep "$DEVICE_GREP " | awk '{print $4}')
		declare -g FILESIZE_WHOLE=$(stat -c %s $FILENAME 2>/dev/null)
		declare -g STATUS="status=progress"
		declare -g DD_CONV="conv=fsync"
	fi
}

#>>==========================================================================>>
# DESCRIPTION:  Checked if the USB-Stick or the SD-Card is available
#
# PARAMETER 1:  Checked if the USB-Stick or the SD-Card is available
# PARAMETER 2:  Is the device not available, the script searched until the device is available
# RETURN:       -
# USAGE:        find_out_device
#
# AUTHOR:       TT
# REVIEWER(S):  -
#<<==========================================================================<<
find_out_device() { #Checked if the USB-Stick or SD-Card available
	echo -e "Find out the $DEVICE_TEXT"
	echo -e "Checked if the $DEVICE_TEXT exists"

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
			declare SIZE=$(lsblk $DEVICE 2>/dev/null | grep "$DEVICE_GREP " | awk '{print $4}')
		fi

		if [ -b $DEVICE ]; then
			echo -e "The $DEVICE_TEXT is $SIZE big"
			break
		fi
	done
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
checking_filesize() { #Checked the Filesize
	echo -e "Checked the Filesize of the Image-File"
	echo -e "Filesize of the Image-File: $FILESIZE"
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
checking_devicesize_and_filesize() { #Checked the Sd-Card Size and the filesize
	echo -e "Checking the Size of the $DEVICE_TEXT and the Image-File"
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
			declare SIZE_WHOLE=$(lsblk -b $DEVICE | grep "$DEVICE_GREP " | awk '{print $4}')
		fi

		if [ $SIZE_WHOLE -gt $FILESIZE_WHOLE ] >/dev/null 2>/dev/null; then
			echo -e "$DEVICE_TEXT is bigger then the Image-File "
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
copy_to_device() { #copy the File on the DEVICE
	echo -e "Copy the File on the $DEVICE_TEXT"
	declare -r BLOCKS=4M
	warning_trace "All data on $DEVICE will be overwritten! Press Strg+C to abort"
	for i in {0..5}; do
		echo -ne "$i /5"'\r'
		sleep 1
	done
	echo
	is_device_read_only
	set +e
	sudo dd if=$FILENAME oflag=direct of=$DEVICE $DD_CONV bs=$BLOCKS $STATUS conv=fdatasync
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
copy_back_from_the_device() { #Copy the File from the SD-Card or USB-STick back into an File
	echo -e "Copying the file back into an verify file"
	declare -r BLOCKS_BACK=4000000
	if [ $FILESIZE_WHOLE -lt $BLOCKS_BACK ]; then
		COUNT=1
	else
		COUNT=$((FILESIZE_WHOLE / BLOCKS_BACK + 2))
	fi
	set +e
	is_device_read_only
	sudo dd if=$DEVICE of=verify.img $DD_CONV bs=$BLOCKS_BACK count=$COUNT $STATUS conv=fdatasync
	not_available_device
	set -e
	echo -e "Shortening the verify file in the size from the original file"
	sudo truncate -r $FILENAME verify.img
}

is_device_read_only() {
	sudo dd if=/dev/null of=$DEVICE 2>/dev/null
	if [ $? = 1 ]; then
		error_trace "The Device is read-only"
		help_trace "Please flip the switch over"
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
	echo -e "Compareing the hash values from the downloaded File and the verify File"
	declare -r MD5SUM=$(md5sum $FILENAME | cut -d" " -f1)
	declare -r MD5SUM_BACK=$(md5sum verify.img | cut -d" " -f1)
	if [ $MD5SUM == $MD5SUM_BACK ]; then
		correct_trace "The hash values are right"
	else
		error_trace "The hash values are not right, please try it again"
		error_trace "Unsuccessfully verifying"
		exit
	fi
}

summary() {
	if [ $ARG_OPTION = -d ]; then
		summary_download_text
	elif [ $ARG_OPTION = --download ]; then
		summary_download_text
	else
		summary_both_text
	fi
}

summary_download_text() {
	echo -e "download process successful, download of the file was successful"
	summary_both_text
}

summary_both_text() {
	echo -e "copy process successful, copy the file to the device was successful"
	echo -e "verifying process successful, the hash values are the same"
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

warning_trace() {
	echo -e "\n${OR_BEG}WARNING: $1${COL_END}"
}

bold_trace_tp() {
	read -r -p "${BOLD_TP}$1 ${TP_END}" $2
}


checkstep() {
	echo -e "${PUR_BEG}$@ ...${COL_END}"
	if $@; then
		printf "%-90b %10b\n" "${PUR_BEG}$1${COL_END}" "${GREEN_BEG} OK ${COL_END}"
	else
		printf "%-90b %10\n" "${PUR_BEG}$1${COL_END}" "${RED_BEG} FAIL ${COL_END}"
		exit
	fi
}


if [ $# -lt 2 ]; then #in the case they are less then 2 Parameter are given, then spend a text
	help_for_less_Parameter
	exit
fi

if ! [ $ARG_OPTION = --help ]; then
    sudo ls >/dev/null 2>/dev/null
fi

trap delete_returned_file exit
trap delete_returned_file term

declare -r LINK=$2
declare FILENAME="$(basename $2)"

declare MAC_SUPPORT=$(sw_vers 2>/dev/null | grep ProductName | awk '{print $2}')

mode_beg

needed_tools

if [ $ARG_OPTION = -d ]; then
	declare FILENAME="$(basename $2)"
elif [ $ARG_OPTION = --download ]; then
	declare FILENAME="$(basename $2)"
else
	declare FILENAME=$2
fi

Parameter=($@)

for ((i = 0; i < ${#Parameter[@]}; i = i + 2)); do
	case ${Parameter[$i]} in
	"-t") ;&
	"--target")
		declare -g ANSWER=${Parameter[$i + 1]}
		;;

	"-v") ;&
	"--value")
		declare -g CHECKVALUE=${Parameter[$i + 1]}
		declare -g CHECKVALUESUM="$(expr length ${Parameter[$i + 1]})"
		declare -g VALUE=${Parameter[$i + 1]}
		;;

	"-u") ;&
	"--user")
		declare -g USER=${Parameter[$i + 1]}
		declare -g DATA=Y
		;;

	"-p") ;&
	"--password")
		declare -g PASSWORD=${Parameter[$i + 1]}
		declare -g DATA=Y
		;;

	*)
		declare -g CHECKVALUE=""
		declare -g CHECKVALUESUM=""
		declare -g VALUE=""
		declare -g USER=""
		declare -g PASSWORD=""
		declare -g ANSWER=""
		;;

	esac
done

case $ARG_OPTION in
"-d") ;&
"--download")
	head_trace "download process and verifikation"
	checkstep download_the_software
	echo ""
	;;

"-c") ;&
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

if [[ "$FILENAME" =~ ".bz2" ]]; then
	declare -g FILENAME=$(echo $2 | sed 's/.$//' | sed 's/.$//' | sed 's/.$//' | sed 's/.$//')
elif [[ "$FILENAME" =~ ".gz" ]]; then
	declare -g FILENAME=$(echo $2 | sed 's/.$//' | sed 's/.$//' | sed 's/.$//')
elif [[ "$FILENAME" =~ ".zip" ]]; then
    declare -g FILENAME=$(echo $2 | sed 's/.$//' | sed 's/.$//' | sed 's/.$//' | sed 's/.$//')
elif [[ "$FILENAME" =~ ".7z" ]]; then
    declare -g FILENAME=$(echo $2 | sed 's/.$//' | sed 's/.$//' | sed 's/.$//')
fi

declare FILESIZE=$(du -h $FILENAME | awk '{print $1}')
declare SIZE=""
declare SIZE_WHOLE=""
declare MAC_SUPPORT=$(sw_vers 2>/dev/null | grep ProductName | awk '{print $2}')
declare DD_CONV=""

if ! [ $ANSWER ]; then
	read_p_text
fi

set +e

lsblk $ANSWER >/dev/null 2>/dev/null

if [ $? -gt 1 ]; then
	error_trace "The device is not available"
	help_trace "Please try it again"
	while true; do
		sleep 1
		read_p_text
		lsblk $ANSWER >/dev/null 2>/dev/null
		if ! [ $? -gt 1 ]; then
			break
		elif [ $? == 1 ]; then
			error_trace "The device is not available"
			help_trace "Please try it again"
		fi
	done
fi

set -e

declare DEVICE=$ANSWER 2>/dev/null
declare DEVICE_GREP=$(basename $DEVICE)
declare SIZE_WHOLE=$(diskutil info /dev/disk2 2>/dev/null | grep 'Disk Size' | cut -b 2-11)
declare FILESIZE_WHOLE=$(stat -l $FILENAME 2>/dev/null | awk '{print $5}')
declare -r DEVICE_TEXT="Device"
declare STATUS=""

variable

head_trace "Detecting Device and copy process"

checkstep find_out_device

echo ""

checkstep checking_filesize

echo ""

checkstep checking_devicesize_and_filesize

echo ""

checkstep copy_to_device

echo ""

head_trace "Verifying"

checkstep copy_back_from_the_device

echo ""

checkstep compare_hash_values

head_trace_end

echo ""

correct_trace "SUCCESS"

head_trace_end

echo ""

declare TIME_END=$(date +%s)

delete_returned_file

summary

echo ""

echo "elapsed time for the whole Script:" $((TIME_END - $TIME_START)) "seconds"

echo -e "You can remove the device"
