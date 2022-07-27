#!/bin/bash
echo "running make clean..."
cd ./libpng && make clean > /dev/null
echo "configuring with sse..."
./configure --enable-intel-sse=yes > /dev/null
echo "running make..."
make > /dev/null
echo "running make install..."
sudo make install > /dev/null
echo "done"
cd ..
