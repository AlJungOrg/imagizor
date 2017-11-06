#!/bin/bash
   
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
   
set +u
set -e
#set -x

#echo -e "$0 Parameter: $*"

declare RED_BEG="\\033[31m"
declare PUR_BEG="\\033[35m"
declare GREEN_BEG="\\033[32m"
declare BLUE_BEG="\\033[34m"
declare TUERK_BEG="\\033[34m"
declare COL_END="\\033[0m"
declare Underline="\\033[4m"

declare ARG_OPTION=$1

set -u

needed_tools() {        #Validate if the needed tool are on the shell
set +e
    
    wget 2>/dev/null
    if [ $? -gt 2 ]; then
        error_trace "Wget isn't install on your shell"
        error_trace "Please install wget"
        exit
    else 
        echo
    fi
    
    gunzip 2>/dev/null

    if [ $? -gt 2 ]; then
        error_trace "gunzip isn't install on your shell"
        error_trace "Please install gunzip"
        exit
    else 
        echo
    fi
    
    dd d 2>/dev/null
    if [ $? -gt 2 ]; then
        error_trace "dd isn't install on your shell"
        error_trace "Please install dd"
        exit
    else 
        echo
    fi
    
    md5sum d 2>/dev/null
    if [ $? -gt 2 ]; then
        error_trace "md5sum isn't install on your shell"
        error_trace "Please install m5sum"
        exit
    else 
        echo
    fi
    set -e
}

needed_truncate() {
    set +e
    truncate d 2>/dev/null
    if [ $? -gt 2 ]; then
        error_trace "truncate isn't install on your shell"
        error_trace "Please install truncate"
        exit
    else 
        echo
    fi
    set -e
}

needed_truncate_OS() {
    set +e
    if [ -e /usr/local/bin/truncate ]; then
        echo
    else
        error_trace "truncate isn't install on your shell"
        error_trace "Please install truncate"
        exit
    fi
    set -e
}
    
download() {             #Download the Software and unpack them, if required 
    Head_trace "download process and verifikation"
    Info_trace "Download the Software"
    if ! wget -c $LINK; then
        error_trace "Maybe the URL is not available or the URL ist passed off "
        help
        exit
    fi
    download_verifikation
    Info_trace "Try to unpack the downloaded Software"
    if ! gunzip  $FILENAME >/dev/null 2>/dev/null; then
        unpack_text
    fi
}

download_verifikation() {
    echo -e "Please enter a check value methodik"
    read -p "mdsum, sha256, I dont have a checkvalue [m,s,a]:" check
    
case $check in
    m|md|M|MD|md5sum|MD5SUM)
        read -p "Now enter the Check value number:" value 
        declare MD_FILE=$(md5sum $FILENAME | cut -d" " -f1)
        
        if [ $MD_FILE == $value ]; then
            Correct_trace "Hash values are the same"
            Correct_trace "Verifikation successfull"
        else 
            error_trace "Hash values are not the same"
            Help_trace "Ples try it again"
            Help_trace "Verifikation Unsuccessfully"
            exit
        fi
        ;;
        
    s|S|Sha|sha|SHA|sha256|SHA256|256)
        read -p "Now enter the Check value number:" value 
        declare Mac_support=$(sw_vers 2>/dev/null | grep ProductName | awk '{print $2}')
        if [ $Mac_support = Mac ] 2>/dev/null; then
            declare SH_FILE=$(shasum -a 256 $FILENAME 2>/dev/null | cut -d" " -f1 )
        else
            declare SH_FILE=$(sha256sum $FILENAME 2>/dev/null | cut -d" " -f1 )
        fi
    
        if [ $SH_FILE == $value ]; then
            Correct_trace "Hash values are the same"
            Correct_trace "Verifikation successfull"
        else 
            error_trace "Hash values are not the same"
            Help_trace "Ples try it again"
            Help_trace "Verifikation Unsuccessfully"
            exit
        fi
            
        ;;
        
    a|A)
    
        ;;
        
esac
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

detect_device () {  #Checked if the USb-Stick or SD-Card available
    Head_trace "Find out the $DEVICE_TEXT"
    Info_trace "Checked if the $DEVICE_TEXT exists"
    
    if ! [ -b $DEVICE ]; then 
        error_trace "$DEVICE_TEXT is not available"
        Help_trace "Please put a $DEVICE_TEXT in"
        Help_trace "At least $FILESIZE are needed"
    fi
    while true; do 
        sleep 1
        if [ $Mac_support = Mac ] 2>/dev/null; then
            declare SIZE=$(diskutil info $DEVICE 2>/dev/null | grep 'Disk Size' | awk '{print $3}' )
        else
            declare SIZE=$(lsblk $DEVICE 2>/dev/null | grep "$DEVICE_GREP"  | awk '{print $4}' )
        fi
        
    if [ -b $DEVICE ]; then
        SIZE_trace "The $DEVICE_TEXT is $SIZE big"
        break
    fi
    done
}

Checked_Device_and_FileSize () {      #Checked the Sd-Card Size and the Filesize
    Head_trace "Checking Size"
    Info_trace "Checked the Size of the $DEVICE_TEXT and the Image-File"
    if [ $SIZE_WHOLE -lt $FILESIZE_WHOLE ] >/dev/null 2>/dev/null; then
        error_trace "$DEVICE_TEXT has less memory space"
        Help_trace "Please put a new $DEVICE_TEXT in"
        Help_trace "Or provide more memory Space"
        Help_trace "At least $FILESIZE are needed"
    fi
    while true; do
        sleep 1
    if [ $Mac_support = Mac ] 2>/dev/null; then
        declare SIZE_WHOLE=$(diskutil info $DEVICE 2>/dev/null | grep 'Disk Size' | awk '{print $5}' | cut -b 2-11 )
    else
        declare SIZE_WHOLE=$(lsblk -b $DEVICE  | grep "$DEVICE_GREP"  | awk '{print $4}' )
    fi
    
    if [ $SIZE_WHOLE -gt $FILESIZE_WHOLE ] >/dev/null 2>/dev/null; then
        Correct_trace "$DEVICE_TEXT is bigger then the Image-File "
        break
    fi
    done 
}

Copy () {             #Copy the File on the DEVICE
    Head_trace "Copy process"
    Info_trace "Copy the File on the $DEVICE_TEXT"
    declare BLOCKS=8000000
    sudo dd if=$FILENAME of=$DEVICE $DD_CONV bs=$BLOCKS count=$((FILESIZE_WHOLE)) $STATUS
}

Copy_back() {           #Copy the File from the SD-Card or USB-STick back into an File
    Head_trace "Verifying"
    Info_trace "Copy the File from the $DEVICE_TEXT back into an File"
    declare BLOCKS_BACK=1000000
    sudo dd if=$DEVICE of=verify.img $DD_CONV bs=$BLOCKS_BACK count=$((FILESIZE_WHOLE)) $STATUS 
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

read_p_text() {
    echo -e "Do you want to copy on the SD-Card or on the USB-Stick?"
    read -p "SD-Card,USB-Stick [S,U]:" answer
}

variable() {
    if [ $Mac_support = Mac ] 2>/dev/null; then
        declare  DEVICE=""
    else
        declare -g DEVICE=$DEVICE_LINUX
        declare -g SIZE=$(lsblk $DEVICE 2>/dev/null | grep "$DEVICE_GREP"  | awk '{print $4}' )
        declare -g FILESIZE_WHOLE=$(stat -c %s $FILENAME 2>/dev/null )
        declare -g STATUS="status=progress"
        declare -g DD_CONV="conv=fdatasync"
    fi
}

if [ $# -lt 2 ]; then   #in the case they are less then 2 Parameter are given, then spend a text
   help_for_less_Parameter
   exit
fi

trap delete_returned_file exit
trap delete_returned_file term 

declare LINK=$2 
declare FILENAME="$(basename $2)"

declare Mac_support=$(sw_vers 2>/dev/null | grep ProductName | awk '{print $2}')

if [ $Mac_support = Mac ] 2>/dev/null; then
    needed_tools
    needed_truncate_OS
else
    needed_tools
    needed_truncate
fi

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
declare SDCard_DEVICE=/dev/mmcblk0
declare USB_DEVICE=/dev/sdb
declare SIZE=""
declare SIZE_WHOLE=""
declare Mac_support=$(sw_vers 2>/dev/null | grep ProductName | awk '{print $2}')
declare DEVICE_LINUX=/dev/sdb

    read_p_text 
    
case "$answer" in
    USB|USB-Stick|Usb-Stick|usb-stick|Usb|usb|u|U)
    
        declare DEVICE_LINUX=/dev/sdb 2>/dev/null
        declare DEVICE=/dev/disk3
        declare SIZE_WHOLE=$(diskutil info /dev/disk3 2>/dev/null | grep 'Disk Size' | awk '{print $5}' | cut -b 2-11 )
        declare FILESIZE_WHOLE=$(stat -l $FILENAME 2>/dev/null | awk '{print $5}')
        declare DEVICE_TEXT="USB-Stick"
        declare DEVICE_GREP="sdb " 
        declare STATUS=""
        
        variable
        
        detect_device
        
        Checked_Device_and_FileSize
        
        Filesize
        
        Copy
        
        Copy_back
        
        Compare_hash_values
        
        Info_trace "Delete the returned File"
        
        delete_returned_file
         
        Correct_trace "You can remove the USB-Stick"
        ;;
        
    SD-Card|Sd-Card|sd-Card|sd-card|SD|Sd|sd|S|s)
        
        if [ -e /dev/sde ]; then
            declare DEVICE_LINUX=/dev/sde 2>/dev/null
            declare DEVICE_GREP="sde "
        else
            declare DEVICE_LINUX=/dev/mmcblk0 2>/dev/null
            declare DEVICE_GREP="mmcblk0 "
        fi
        declare DEVICE=/dev/disk2
        declare SIZE_WHOLE=$(diskutil info /dev/disk2 2>/dev/null | grep 'Disk Size' | awk '{print $5}' | cut -b 2-11 )
        declare FILESIZE_WHOLE=$(stat -l $FILENAME 2>/dev/null | awk '{print $5}')
        declare DEVICE_TEXT="SD-Card"
        declare STATUS=""
        
        variable
        
        detect_device

        Checked_Device_and_FileSize

        Filesize

        Copy  

        Copy_back

        Compare_hash_values

        Info_trace "Delete the returned File"

        delete_returned_file

        Correct_trace "You can remove the Sd-Card"
        ;;
        
esac
