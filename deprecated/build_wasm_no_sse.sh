 #!/bin/bash
echo "running make clean..."
cd ./libpng && make clean > /dev/null
echo "configuring without sse..."
./configure --enable-intel-sse=no > /dev/null
echo "running make..."
make > /dev/null
echo "running make install..."
sudo make install > /dev/null
echo "undefining SETJMP, SIMPLIFIED_READ, and SIMPLIFIED_WRITE..."
cd /usr/local/include/libpng16
sudo sed -i 's/#define PNG_SETJMP_SUPPORTED/#undef PNG_SETJMP_SUPPORTED/g' pnglibconf.h
sudo sed -i 's/#define PNG_SIMPLIFIED_READ_SUPPORTED/#undef PNG_SIMPLIFIED_READ_SUPPORTED/g' pnglibconf.h
sudo sed -i 's/#define PNG_SIMPLIFIED_WRITE_SUPPORTED/#undef PNG_SIMPLIFIED_WRITE_SUPPORTED/g' pnglibconf.h
echo "done"
cd ~/image_decoding
