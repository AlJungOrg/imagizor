#!/usr/bin/expect

cd ..

spawn ./imagizor.sh -d http://download.opensuse.org/distribution/leap/42.3/iso/openSUSE-Leap-42.3-DVD-x86_64.iso.sha256

set timeout 5

expect "md5sum, sha256, I dont have a check value \[m,s,a\] (a):"

send "s\r"

expect "Now enter the Check value number:"

send "1ce040ce418c6009df6e169cff47898f31c54e359b8755177fa7910730556c18\r"

expect "Please choose your Device \[ example: /dev/mmcblk0 \]:"

send "/dev/loop0\r"

set timeout 30

expect "copy_back"

wait

expect eof

