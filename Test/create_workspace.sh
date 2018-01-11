#!/bin/bash

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

#source ../lib/imagizor_common.sh
. ../lib/imagizor_common.sh

declare -r PUR_BEG="\\033[35m"
declare -r COL_END="\\033[0m"
declare -r UNDERLINE="\\033[4m"

declare BLOCKS=500M
declare BLOCKS_BYTE=512
declare COPY_TEXT="Starting the copy mode test"
declare COPY_PARAMETER='imagizor.sh -c test.iso -de /dev/loop0'
declare COUNT=4
declare DATE='date +%Y:%m:%d:%H:%M:%S'
declare DEVICE=/dev/loop0
declare DEVICE_ZERO=/dev/zero
declare DOWNLOAD_TEXT="Starting the download mode test"
declare DOWNLOAD_PARAMETER='imagizor.sh -d http://download.opensuse.org/distribution/leap/42.3/iso/openSUSE-Leap-42.3-DVD-x86_64.iso.sha256 -de /dev/loop0 -u n -p n -ch 1ce040ce418c6009df6e169cff47898f31c54e359b8755177fa7910730556c18'
declare FILE_DEVICE=/virtualfs
declare FILE=test.iso
declare STATUS="status=progress"

head_trace "Create the Workspace"

info_trace "Create the loop device"

echo ""

create_device

sudo losetup $DEVICE $FILE_DEVICE

echo ""

info_trace "Create the test file"

echo ""

cd ..

create_file

(
	echo ""

	echo $($DATE) $DOWNLOAD_TEXT

	echo ""
) >>log1.file

echo -e ""

head_trace "$DOWNLOAD_TEXT"

declare BEFORE_DOWNLOAD=$(date +%s)

(
	download_script

	declare AFTER_DOWNLOAD=$(date +%s)

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

info_trace "Test finished"

(
	echo ""

	echo $($DATE) $COPY_TEXT

	echo ""
) >>log2.file

echo ""

head_trace "$COPY_TEXT"

declare BEFORE_COPY=$(date +%s)

(
	copy_script

	declare AFTER_COPY=$(date +%s)

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

info_trace "Test finished"

echo ""

head_trace "Delete the Workspace"

delete_file

sudo losetup -d $DEVICE

delete_file_device
