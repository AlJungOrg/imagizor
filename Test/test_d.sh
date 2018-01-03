#!/usr/bin/expect

cd ..

spawn ./imagizor.sh -d http://download.opensuse.org/distribution/leap/42.3/iso/openSUSE-Leap-42.3-DVD-x86_64.iso.sha256

set timeout 5

expect "Yes, No [Y, N]:"

send "n\r"

expect "mdsum, sha256, I dont have a checkvalue \[m,s,a\]:"

send "a\r"

expect "Please choose your Device \[ example: /dev/mmcblk0 \]:"

send "/dev/mmcblk0\r"

set timeout 25

expect "copy_back"

wait

expect eof

wait
