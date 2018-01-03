#!/usr/bin/expect

cd ..

spawn ./imagizor.sh -c openSUSE-Leap-42.3-DVD-x86_64.iso.sha256

set timeout 5

expect "Please choose your Device \[ example: /dev/mmcblk0 \]:"

send "/dev/mmcblk0\r"

set timeout 30

expect "copy_back"

wait

expect eof

wait
