#!/bin/bash

Test_successfull() {
if [ $? -gt 1 ]; then
    echo -e "Test gone Wrong"
else 
    echo -e "Test successfull"
fi
}

echo -e "start Test 1..."

./test_c.sh

Test_successfull

cd Test

echo -e "start Test 2..."

./test_d.sh

Test_successfull

echo -e "start Test 3..."

./test_g.sh

Test_successfull

echo -e "start Test 4..."

./test_b.sh

Test_successfull

echo -e "Tests completed"
