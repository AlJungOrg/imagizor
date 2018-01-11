#!/usr/bin/expect

cd ..

spawn ./imagizor.sh -c test.iso

set timeout 5

expect "Please choose your Device \[ example: /dev/mmcblk0 \]:"

send "/dev/loop0\r"

set timeout 30

expect "copy_back"

wait

expect eof


