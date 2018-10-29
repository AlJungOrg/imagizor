#!/usr/bin/expect

cd ../imagizor

spawn ./imagizor.sh -c test.iso

set timeout 5

expect "Please choose your Device \[ Enter the number for the device \]:"

send "/dev/loop0\r"

set timeout 30

expect "copy_back"

wait

expect eof


