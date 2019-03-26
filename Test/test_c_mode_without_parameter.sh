#!/usr/bin/expect

cd ..

spawn ./imagizor.sh -c test.iso

set timeout 5

expect "Please choose your Device \[ Enter the number for the device \]:"

send "/dev/loop0\r"

set timeout 30

expect "copy_back"

expect "Do you want to delete the compressed File? (y):"

send "y\r"

wait

expect eof


