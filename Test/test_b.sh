#!/usr/bin/expect

cd ..

spawn ./imagizor.sh -b test2.bz2

set timeout 5

expect "SD-Card,USB-Stick \[S,U\]:\r"

send "s\r"

set timeout 30

expect "copy_back"

wait

expect eof

wait
