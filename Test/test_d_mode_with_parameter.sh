#!/usr/bin/expect

cd ..

spawn ./imagizor.sh -d http://download.opensuse.org/distribution/leap/42.3/iso/openSUSE-Leap-42.3-DVD-x86_64.iso.sha256 -t /dev/loop0 -u n -p n -v 1ce040ce418c6009df6e169cff47898f31c54e359b8755177fa7910730556c18

set timeout 10

expect "Do you want to delete the compressed File? (y):"

send "n\r"

wait

expect eof
