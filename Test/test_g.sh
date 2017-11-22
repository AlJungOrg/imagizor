#!/usr/bin/expect

cd ..

spawn ./imagizor.sh -g openSUSE-Leap-42.3-DVD-x86_64.iso.sha256.gz

set timeout 5

expect "SD-Card,USB-Stick \[S,U\]:\r"

send "s\r"

set timeout 30

expect "copy_back"

wait

expect eof

wait
