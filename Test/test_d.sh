#!/usr/bin/expect

cd ..

spawn ./imagizor.sh -d http://download.opensuse.org/distribution/leap/42.3/iso/openSUSE-Leap-42.3-DVD-x86_64.iso.sha256

set timeout 5

expect "mdsum, sha256, I dont have a checkvalue \[m,s,a\]:"

send "a\r"

expect "SD-Card,USB-Stick \[S,U\]:\r"

send "s\r"

set timeout 25

expect "copy_back"

wait

expect eof

wait
