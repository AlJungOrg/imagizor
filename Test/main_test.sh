#!/bin/bash

#set -x

. ../lib/imagizor_common.sh

sudo ls >/dev/null 2>/dev/null

if [ whoami = jenkins ]; then 
    declare DIR=/var/lib/jenkins/workspace/Imagizor
else
    declare DIR=~/imagizor
fi

declare -r PUR_BEG="\\033[35m"
declare -r GREEN_BEG="\\033[32m"
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
	if [ $? -gt 1 ]; then
		echo -e "Test gone Wrong"
		cat $DIR/$LOGFILE
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
    
    test_successfull
    
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
	) >>log1.file

	echo -e ""

	declare -g BEFORE=$(date +%s)

	(
		download_script

		function_end_script_text

	) >>log1.file 2>&1

	echo -e ""

	echo -e "Test finished"
}

start_download_test_without_parameter() {
(
		echo ""

		echo $($DATE) $DOWNLOAD_WITHOUT_PARAMETER_TEXT

		echo ""
	) >>log2.file

	echo ""

	declare BEFORE=$(date +%s)
	(
		cd Test
		
		download_script_without_parameter
		
		function_end_script_text

		echo ""

		echo -e "Test finished"

		echo ""
	) >>log2.file
}

start_copy_test() {
	(
		echo ""

		echo $($DATE) $COPY_TEXT

		echo ""
	) >>log3.file

	echo ""

	declare -g BEFORE=$(date +%s)

	(
		copy_script

		function_end_script_text
	) >>log3.file 2>&1

	echo ""

	echo -e "Test finished"

	echo ""
}

start_copy_test_without_parameter() {

	(
		echo ""

		echo $($DATE) $COPY_WITHOUT_PARAMETER_TEXT

		echo ""
	) >>log4.file

	echo ""

	declare BEFORE=$(date +%s)
	(
		cd Test
		
		copy_script_without_parameter
		
		function_end_script_text

		echo ""

		echo -e "Test finished"

		echo ""
	) >>log4.file
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
	else
		printf "%-90b %10\n" "${PUR_BEG}$1${COL_END}" "${RED_BEG} FAIL ${COL_END}"
		NOF_FAILED_COMMANDS=$NOF_FAILED_COMMANDS+1
	fi
}

#source ../lib/imagizor_common.sh

head_trace "Create the Workspace"

checkstep create_the_workspace

declare LOGFILE=log1.file

head_trace "$DOWNLOAD_TEXT"

checkstep start_download_test

declare LOGFILE=log2.file

head_trace "$DOWNLOAD_WITHOUT_PARAMETER_TEXT"

checkstep start_download_test_without_parameter

declare LOGFILE=log3.file

head_trace "$COPY_TEXT"

checkstep start_copy_test

declare LOGFILE=log4.file

head_trace "$COPY_WITHOUT_PARAMETER_TEXT"

checkstep start_copy_test_without_parameter

head_trace "Delete the Workspace"

checkstep delete_the_workspace

echo ""

if [ $NOF_FAILED_COMMANDS -gt 0 ]; then
    info_trace "Failed script count: $NOF_FAILED_COMMANDS"
fi

head_trace_end
