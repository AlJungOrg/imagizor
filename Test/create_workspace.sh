#!/bin/bash

#set -x

. ../lib/imagizor_common.sh

declare -r PUR_BEG="\\033[35m"
declare -r GREEN_BEG="\\033[32m"
declare -r COL_END="\\033[0m"
declare -r UNDERLINE="\\033[4m"

declare BLOCKS=500M
declare BLOCKS_BYTE=512
declare COPY_TEXT="Starting the copy mode test"
declare COPY_PARAMETER='imagizor.sh -c test.iso -t /dev/loop0'
declare COUNT=4
declare DATE='date +%Y:%m:%d:%H:%M:%S'
declare DEVICE=/dev/loop0
declare DEVICE_ZERO=/dev/zero
declare DOWNLOAD_TEXT="Starting the download mode test"
declare DOWNLOAD_PARAMETER='imagizor.sh -d http://download.opensuse.org/distribution/leap/42.3/iso/openSUSE-Leap-42.3-DVD-x86_64.iso.sha256 -t /dev/loop0 -u n -p n -v 1ce040ce418c6009df6e169cff47898f31c54e359b8755177fa7910730556c18'
declare FILE_DEVICE=/virtualfs
declare FILE=test.iso
declare STATUS="status=progress"

test_successfull() {
	if [ $? -gt 1 ]; then
		echo -e "Test gone Wrong"
		exit
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

copy_script() {
	bash -n $COPY_PARAMETER
	sudo ./$COPY_PARAMETER
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

	(
		echo ""

		echo $($DATE) $DOWNLOAD_TEXT

		echo ""
	) >>log1.file

	echo -e ""
}

start_download_test() {

	declare -g BEFORE_DOWNLOAD=$(date +%s)

	   (download_script

		declare -g AFTER_DOWNLOAD=$(date +%s)

		echo ""

		test_successfull

		echo $($DATE)

		echo ""

		echo "elapsed time:" $((AFTER_DOWNLOAD - $BEFORE_DOWNLOAD)) "seconds"

		echo ""

		echo -e "last named commit:"
		git log --pretty=format:"%s" | head -n 1

		echo -e ""

		echo -e "last hash commit:"
		git log --pretty=format:"%H" | head -n 1

		echo "-------------------------------------------------------------------------------------------------------"
	) >>log1.file 2>&1

	echo -e ""

	echo -e "Test finished"

		(echo ""

		echo $($DATE) $COPY_TEXT

		echo ""
	) >>log2.file

	echo ""
}

start_copy_test() {

	declare -g BEFORE_COPY=$(date +%s)

	(
		copy_script

		declare -g AFTER_COPY=$(date +%s)

		echo ""

		test_successfull

		echo $($DATE)

		echo ""

		echo "elapsed time:" $((AFTER_COPY - $BEFORE_COPY)) "seconds"

		echo ""

		echo -e "last named commit:"
		git log --pretty=format:"%s" | head -n 1

		echo -e ""

		echo -e "last hash commit:"
		git log --pretty=format:"%H" | head -n 1

		echo "-------------------------------------------------------------------------------------------------------"
	) >>log2.file 2>&1

	echo ""

	echo -e "Test finished"

	echo ""
}



delete_the_workspace() {

	delete_file

	sudo losetup -d $DEVICE

	delete_file_device
}

#source ../lib/imagizor_common.sh

head_trace "Create the Workspace"

checkstep create_the_workspace

head_trace "$DOWNLOAD_TEXT"

checkstep start_download_test

head_trace "$COPY_TEXT"

checkstep start_copy_test

head_trace "Delete the Workspace"

checkstep delete_the_workspace

head_trace_end
