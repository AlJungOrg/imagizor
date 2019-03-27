#!/usr/bin/expect

cd ..

spawn ./imagizor.sh -c test.iso -t /dev/loop0

set timeout 10

expect "Do you want to delete the compressed File? (y):"

send "n\r"

wait

expect eof
