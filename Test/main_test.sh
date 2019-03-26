#!/bin/bash

#set -x

. ../lib/imagizor_common.sh

sudo ls >/dev/null 2>/dev/null

if [ whoami = jenkins ]; then
	declare DIR=/var/lib/jenkins/workspace/Imagizor/Test
	declare DIR_IM=/var/lib/jenkins/workspace/Imagizor
else
	declare DIR=~/imagizor/Test
    declare DIR_IM=~/imagizor
fi

declare -r PUR_BEG="\\033[35m"
declare -r GREEN_BEG="\\033[32m"
declare -r RED_BEG="\\033[31m"
declare -r COL_END="\\033[0m"
declare -r UNDERLINE="\\033[4m"

declare BLOCKS=500M
declare BLOCKS_BYTE=512
declare COPY_TEXT="Starting the copy mode test"
declare COPY_WITHOUT_PARAMETER_TEXT="Starting the copy mode test without any parameter"
declare COPY_PARAMETER='imagizor.sh -c test.iso -t /dev/loop0'
declare COPY_WITHOUT_PARAMETER='test_c_mode_without_parameter.sh'
declare COUNT=4
declare DATE='date +%Y:%m:%d:%H:%M:%S'
declare DEVICE=/dev/loop0
declare DEVICE_ZERO=/dev/zero
declare DOWNLOAD_TEXT="Starting the download mode test"
declare DOWNLOAD_WITHOUT_PARAMETER_TEXT="Starting the download mode test without any parameter"
declare DOWNLOAD_PARAMETER='imagizor.sh -d http://download.opensuse.org/distribution/leap/42.3/iso/openSUSE-Leap-42.3-DVD-x86_64.iso.sha256 -t /dev/loop0 -u n -p n -v 1ce040ce418c6009df6e169cff47898f31c54e359b8755177fa7910730556c18'
declare DOWNLOAD_WITHOUT_PARAMETER='test_d_mode_without_parameter.sh'

declare FILE_DEVICE=/virtualfs
declare FILE=test.iso
declare STATUS="status=progress"

test_successfull() {
	if [ $? -gt 0 ]; then
		echo -e "Test gone Wrong"
		declare -g CORRECT=1
	else
		echo -e "Test successfull"
	fi
}

create_file() {
	sudo dd if=$DEVICE_ZERO of=$FILE bs=$BLOCKS_BYTE count=$COUNT $STATUS
}

create_device() {
	sudo dd if=$DEVICE_ZERO of=$FILE_DEVICE bs=$BLOCKS count=$COUNT $STATUS
}

download_script() {
	bash -n $DOWNLOAD_PARAMETER
	sudo ./$DOWNLOAD_PARAMETER
}

download_script_without_parameter() {
	bash -n test_d_mode_without_parameter.sh
	sudo ./test_d_mode_without_parameter.sh
}

copy_script() {
	bash -n $COPY_PARAMETER
	sudo ./$COPY_PARAMETER
}

copy_script_without_parameter() {
	bash -n test_c_mode_without_parameter.sh
	sudo ./test_c_mode_without_parameter.sh
}

function_end_script_text() {


	declare -g AFTER=$(date +%s)

	echo ""

	echo $($DATE)

	echo ""

	echo "elapsed time:" $((AFTER - $BEFORE)) "seconds"

	echo ""

	echo -e "last named commit:"
	git log --pretty=format:"%s" | head -n 1

	echo -e ""

	echo -e "last hash commit:"
	git log --pretty=format:"%H" | head -n 1

	echo "-------------------------------------------------------------------------------------------------------"
}

delete_file() {
	sudo rm -r $FILE
}

delete_file_device() {
	sudo rm -r $FILE_DEVICE
}

create_the_workspace() {

	echo -e "Create the loop device"

	echo ""

	create_device

	sudo losetup $DEVICE $FILE_DEVICE

	echo ""

	echo -e "Create the test file"

	echo ""

	cd ..

	create_file

}

start_download_test() {
    
	(
		echo ""

		echo $($DATE) $DOWNLOAD_TEXT

		echo ""
	) >>download.file

	echo -e ""

	declare -g BEFORE=$(date +%s)

	(
		download_script
    
	) >>download.file 2>&1
	
	test_successfull
    
	(	function_end_script_text

	) >>download.file 2>&1

	echo -e ""

	echo -e "Test finished"
	
	declare -g CORRECT=0
}

start_download_test_without_parameter() {
	(
		echo ""

		echo $($DATE) $DOWNLOAD_WITHOUT_PARAMETER_TEXT

		echo ""
	) >>download_without_parameter.file

	echo ""

	declare BEFORE=$(date +%s)
	(
		cd Test

		download_script_without_parameter

		) >>download_without_parameter.file 2>&1
	
	test_successfull
    
	(
		
		function_end_script_text

	) >>download_without_parameter.file 2>&1
	
	echo ""

	echo -e "Test finished"

	echo ""
	
	declare -g CORRECT=0
}

start_copy_test() {
	(
		echo ""

		echo $($DATE) $COPY_TEXT

		echo ""
	) >>copy.file

	echo ""

	declare -g BEFORE=$(date +%s)

	(
		copy_script

    ) >>copy.file 2>&1
	
	test_successfull
    
	(
		
		function_end_script_text
	) >>copy.file 2>&1
	
	echo ""

	echo -e "Test finished"

	echo ""
	
	declare -g CORRECT=0
}

start_copy_test_without_parameter() {

	(
		echo ""

		echo $($DATE) $COPY_WITHOUT_PARAMETER_TEXT

		echo ""
	) >>copy_without_parameter.file

	echo ""

	declare BEFORE=$(date +%s)
	(
		cd Test

		copy_script_without_parameter

    ) >>copy_without_parameter.file
	 
	test_successfull
    
	(
		
		function_end_script_text

	) >>copy_without_parameter.file

	echo ""

	echo -e "Test finished"

	echo ""
	
	declare -g CORRECT=0
}

delete_the_workspace() {

	delete_file

	sudo losetup -d $DEVICE

	delete_file_device
}

checkstep() {
	echo -e "${PUR_BEG}$@ ...${COL_END}"
	if $@; then
		printf "%-90b %10b\n" "${PUR_BEG}$1${COL_END}" "${GREEN_BEG} OK ${COL_END}"
	elif [ $CORRECT==1 ]; then
        printf "%-90b %10b\n" "${PUR_BEG}$1${COL_END}" "${RED_BEG} FAIL ${COL_END}"
		declare -g NOF_FAILED_COMMANDS=$(( NOF_FAILED_COMMANDS + 1 ))
	else
		printf "%-90b %10b\n" "${PUR_BEG}$1${COL_END}" "${RED_BEG} FAIL ${COL_END}"
		declare -g NOF_FAILED_COMMANDS=$(( NOF_FAILED_COMMANDS + 1 ))
	fi
}

html_function() {
cat $DIR_IM/$LOGFILE|$DIR/ansi2html.sh > $DIR_IM/$LOGFILE
}

declare -g CORRECT=0

#source ../lib/imagizor_common.sh

head_trace "Create the Workspace"

checkstep create_the_workspace

declare -g LOGFILE=download.file
declare -g HTMLFILE=download_html.file

head_trace "$DOWNLOAD_TEXT"

checkstep start_download_test

declare LOGFILE=download_without_parameter.file
declare HTMLFILE=download_without_parameter_html.file

head_trace "$DOWNLOAD_WITHOUT_PARAMETER_TEXT"

checkstep start_download_test_without_parameter

declare LOGFILE=copy.file
declare HTMLFILE=copy_html.file

head_trace "$COPY_TEXT"

checkstep start_copy_test

declare LOGFILE=copy_without_parameter.file
declare HTMLFILE=copy_without_parameter_html.file

head_trace "$COPY_WITHOUT_PARAMETER_TEXT"

checkstep start_copy_test_without_parameter

head_trace "Delete the Workspace"

checkstep delete_the_workspace

echo ""

if [ $NOF_FAILED_COMMANDS ]; then
	info_trace "Failed script count: $NOF_FAILED_COMMANDS"
fi

head_trace_end
