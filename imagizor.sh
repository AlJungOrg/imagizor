#!/bin/bash
   
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
   
set +u
set -e
#set -x

#echo -e "$0 Parameter: $*"

declare RED_BEG="\\033[01;33m\e[31m"
declare PUR_BEG="\\033[01;33m\e[35m"
declare GREEN_BEG="\\033[01;33m\e[32m"
declare BLUE_BEG="\\033[01;33m\e[34m"
declare TUERK_BEG="\\033[01;33m\e[34m"
declare COL_END="\\033[;0m"
declare Underline="\\033[4m"

declare ARG_OPTION=$1

set -u

download() {             #Download the Software and unpack them, if required 
    Head_trace "download process"
    Info_trace "Download the Software"
    if ! wget $LINK; then
        error_trace "Maybe the URL is not available or the URL ist passed off "
        help
        exit
    fi
    Info_trace "Try to unpack the downloaded Software"
    if ! gunzip  $FILENAME >/dev/null 2>/dev/null; then
        unpack_text
    fi
}

unpack() {               #Unpack the Software
    Head_trace "Unpack process"
    Info_trace "Unpack the Software"
    if ! gunzip $FILENAME >/dev/null 2>/dev/null; then
        unpack_text
        exit
    fi
}

unpack_text() {      #Text for the unpack part
    echo -e "Unpack is not required"
}

help() {                    #Is a help text
    echo -e "invalid command"
    echo -e "Call: ./image_to_device.sh [-d, --download, -g, --gunzip] [Downloadlink, File to unpack]"
    echo -e "Example: ./imagizor.sh -d http://download.opensuse.org/distribution/leap/42.3/iso/openSUSE-Leap-42.3-DVD-x86_64.iso.sha256"
    exit 
}

Parameter_show() {          #Checked if more then 2 Parameter are given
    if [ $# -lt 2 ]; then   
        help_for_less_Parameter
    fi
}

help_for_less_Parameter () {     #Longer help text
    echo -e "Call: ./image_to_device.sh [-d, --download, -g, --gunzip] [Downloadlink, File to unpack]"
    echo -e "./image_to_device.sh                    -g      --gunzip                            File to unpack"
    echo -e "./image_to_device.sh                    -d      --download                          Downloadlink"
    echo -e "Example: ./imagizor.sh -d http://download.opensuse.org/distribution/leap/42.3/iso/openSUSE-Leap-42.3-DVD-x86_64.iso.sha256"
    exit
}

Find_Out_SD_Card () {     #Checked if the SD-Card exists
    Head_trace "Find out the SD-Card"
    Info_trace "Checked if the SD-Card exists"
    if ! [ -e /dev/mmcblk0 ]; then 
        error_trace "SD-Card is not available"
        Help_trace "Please put a SD-Card in"
        Help_trace "At least $FILESIZE are needed"
    fi
    while true; do 
        sleep 1
        declare SIZE=$(lsblk $SDCard_DEVICE 2>/dev/null | grep "mmcblk0 " | awk '{print $4}' )
    if [ -e /dev/mmcblk0 ]; then
        SIZE_trace "The SD-Card is $SIZE big"
        break
    fi
    done
}

Find_USB_stick_out () {  #Checked if the USb-Stick exists
    Head_trace "Find out the USB-Stick"
    Info_trace "Checked if the USB-Stick exists"
    if ! [ -b /dev/sdb ]; then 
        error_trace "USB-Stick is not available"
        Help_trace "Please put a SD-Card in"
        Help_trace "At least $FILESIZE are needed"
    fi
    while true; do 
        sleep 1
        declare SIZE=$(lsblk $USB_DEVICE 2>/dev/null | grep "sdb " | awk '{print $4}' )
    if [ -b /dev/sdb ]; then
        SIZE_trace "The USB-Stick is $SIZE big"
        break
    fi
    done
}

Checked_SD-Card_and_FileSize () {      #Checked the Sd-Card Size and the Filesize
    Head_trace "Checking Size"
    Info_trace "Checked the Size of the SD-Card and the Image-File"
    declare SIZE_WHOLE=$(lsblk -b $SDCard_DEVICE 2>/dev/null | grep "mmcblk0 " | awk '{print $4}' )
    if [ $SIZE_WHOLE -lt $FILESIZE_WHOLE ] >/dev/null 2>/dev/null; then
        error_trace "SD-Card has less memory space"
        Help_trace "Please put a new SD-Card in"
        Help_trace "Or provide more memory Space"
        Help_trace "At least $FILSIZE are needed"
    fi
    while true; do
        sleep 1
    declare SIZE_WHOLE=$(lsblk -b $SDCard_DEVICE 2>/dev/null | grep "mmcblk0 " | awk '{print $4}' )
    if [ $SIZE_WHOLE -gt $FILESIZE_WHOLE ] >/dev/null 2>/dev/null; then
        Correct_trace "SD-Card is bigger then the Image-File "
        break
    fi
    done 
}

Checked_USB_Stick_and_FileSize () {      #Checked the USB-Stick Size and the Filesize
    Head_trace "Checking Size"
    Info_trace "Checked the Size of the USB-Stick and the Image-File"
    declare SIZE_WHOLE=$(lsblk -b $USB_DEVICE 2>/dev/null | grep "sdb " | awk '{print $4}' )
    if [ $SIZE_WHOLE -lt $FILESIZE_WHOLE ] >/dev/null 2>/dev/null; then
        error_trace "USb-Stick has less memory space"
        Help_trace "Please put a new USB-Stick in"
        Help_trace "Or provide more memory Space"
        Help_trace "At least $FILSIZE are needed"
    fi
    while true; do
        sleep 1
    declare SIZE_WHOLE=$(lsblk -b $USB_DEVICE 2>/dev/null | grep "sdb " | awk '{print $4}' )
    if [ $SIZE_WHOLE -gt $FILESIZE_WHOLE ] >/dev/null 2>/dev/null; then
        Correct_trace "USB-Stick is bigger then the Image-File "
        break
    fi
    done 
}

CopySD () {             #Copy the File on the SD-Card
    Head_trace "Copy process"
    Info_trace "Copy the File on the SD-Card"
    declare BLOCKS=8000000
    sudo dd if=$FILENAME of=$SDCard_DEVICE bs=$BLOCKS count=$((FILESIZE_WHOLE))
    sync
}

CopyUSB () {             #Copy the File on the USB-Stick
    Head_trace "Copy process"
    Info_trace "Copy the File on the SD-Card"
    declare BLOCKS=8000000
    sudo dd if=$FILENAME of=$USB_DEVICE bs=$BLOCKS count=$((FILESIZE_WHOLE))
    sync
}

Copy_back() {           #Copy the File from the SD-Card back into an File
    Head_trace "Verifying"
    Info_trace "Copy the File from the SD-Card back into an File"
    declare -r BLOCKS_BACK=1000000
    sudo dd if=$SDCard_DEVICE of=verify.img bs=$BLOCKS_BACK count=$((FILESIZE_WHOLE))
    sync
    Info_trace "Shortening the returned File in the Size from the original File"
    sudo truncate -r $FILENAME verify.img
}

Copy_back_USB() {           #Copy the File from the USB-Stick back into an File
    Head_trace "Verifying"
    Info_trace "Copy the File from the USB-Stick back into an File"
    declare -r BLOCKS_BACK=1000000
    sudo dd if=$USB_DEVICE of=verify.img bs=$BLOCKS_BACK count=$((FILESIZE_WHOLE))
    sync
    Info_trace "Shortening the returned File in the Size from the original File"
    sudo truncate -r $FILENAME verify.img
}

Filesize () {                       #Checked the Filesize
    Head_trace "Size checking"
    Info_trace "Checked the Filesize of the Image-File"
    SIZE_trace "Filesize of the Image-File: $FILESIZE" 
}

Compare_hash_values() {   #Compares the hash values from the downloaded File and the returned File
    Info_trace "Compare the hash values from the downloaded File and the returned File"
    declare MD5SUM=$(md5sum $FILENAME | cut -d" " -f1)
    declare MD5SUM_BACK=$(md5sum verify.img | cut -d" " -f1)
    if [ $MD5SUM == $MD5SUM_BACK ]; then 
        Correct_trace "The hash values are right"
        Correct_trace "Successfully Verifying "
        else 
        error_trace "The hash values are not right, please try it again"
        error_trace "Unsuccessfully verifying"
    fi
}

delete_returned_file() {  #Delete the returned File
    rm -rf verify.img
}

Info_trace() {          #marked purple
    echo -e "${PUR_BEG}$1${COL_END}"
}

Help_trace() {          #marked RED
    echo -e "${RED_BEG}$1${COL_END}"
}

error_trace() {         #marked RED and added an ERROR at the begining
    echo -e "\n${RED_BEG}ERROR: $1${COL_END}"
}

Correct_trace() {       #marked Green
    echo -e "${GREEN_BEG}$1${COL_END}"
}

SIZE_trace() {          #marked Blue
    echo -e "${BLUE_BEG}$1${COL_END}"
}

Head_trace() {          #create a underline and the text is purple
    echo -e ______________________________________________________________________
    echo -e "\n${Underline}${PUR_BEG}$1${COL_END}\n"
    echo -e ----------------------------------------------------------------------
}  

if [ $# -lt 2 ]; then   #in the case they are less then 2 Parameter are given, then spend a text
    help_for_less_Parameter
    exit
fi

declare LINK=$2 
declare FILENAME="$(basename $2)"

trap delete_returned_file exit
trap delete_returned_file term 

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

declare FILESIZE_WHOLE=$(stat -c %s $FILENAME)
declare FILESIZE=$(du -h $FILENAME | awk '{print $1}') 
declare SDCard_DEVICE=/dev/mmcblk0
declare USB_DEVICE=/dev/sdb
declare SIZE=""
declare SIZE_WHOLE=""

read -p "Do you want to copy on the SD-Card or on the USB-Stick?:" answer

case "$answer" in
    USB|USB-Stick|Usb-Stick|usb-stick|Usb|usb|u|U)
        Find_USB_stick_out
        
        Checked_USB_Stick_and_FileSize
        
        Filesize
        
        CopyUSB
        
        Copy_back_USB
        
        Compare_hash_values
        
        Info_trace "Delete the returned File"
        
        delete_returned_file
         
        Correct_trace "You can remove the USB-Stick"
        ;;
    SD-Card|Sd-Card|sd-Card|sd-card|SD|Sd|sd|S|s)
        Find_Out_SD_Card

        Checked_SD-Card_and_FileSize

        Filesize

        CopySD  

        Copy_back

        Compare_hash_values

        Info_trace "Delete the returned File"

        delete_returned_file

        Correct_trace "You can remove the Sd-Card"
        ;;
esac
