#!/bin/bash

Test_successfull() {
if [ $? -gt 1 ]; then
    echo -e "Test gone Wrong"
else 
    echo -e "Test successfull"
fi
} 

echo -e "Create the Workspace"

sudo dd if=/dev/zero of=/virtualfs bs=1G count=2

sudo losetup /dev/loop0

sudo losetup /dev/loop0 /virtualfs

cd ..

sudo dd if=/dev/random of=test.iso bs=1024 count=2 iflag=fullblock

echo -e "Start Test 1"

sudo ./imagizor.sh -d http://download.opensuse.org/distribution/leap/42.3/iso/openSUSE-Leap-42.3-DVD-x86_64.iso.sha256 -de /dev/loop0 -u n -p n -ch 1ce040ce418c6009df6e169cff47898f31c54e359b8755177fa7910730556c18

Test_successfull

echo -e "Start Test 2"

sudo ./imagizor.sh -c test.iso -de /dev/loop0

Test_successfull

echo -e "Delete the Workspace"

sudo rm -r test.iso

cd Test

sudo losetup -d /dev/loop0
