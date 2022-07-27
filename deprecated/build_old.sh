 #!/bin/bash

Help() {
echo "Build the libpng library for the image decoding algorithm"
echo 
echo "Syntax: bash build.sh [-h|s|w]"
echo "options:"
echo "h    Print this help menu."
echo "s    Build with sse enabled."
echo "w    Disable relavant libpng features for WASM compilation."
echo
}

# Enable and disable SSE during build
# Prepare for WASM usage in compilation
while getopts "hsw" OPTION
do
    case $OPTION in
	h) Help
	   exit;;
        s) sse="true"
	   echo "sse enabled...";;
        w) wasm="true"
	   echo "wasm enabled...";;
    esac
done

# Build the libpng library
echo "running make clean..."
cd ./libpng && make clean > /dev/null
if [[ "$sse" = "true" ]]; then 
	echo "configuring with sse..."
	./configure --enable-intel-sse=yes > /dev/null
else 
	echo "configuring without sse..."
	./configure --enable-intel-sse=no > /dev/null
fi

echo "running make..."
make > /dev/null
echo "running make install..."
sudo make install > /dev/null

# Disable SETJMP if WASM is in use
if [[ "$wasm" = "true" ]]; then
	echo "undefining SETJMP, SIMPLIFIED_READ, and SIMPLIFIED_WRITE..."
	cd /usr/local/include/libpng16
	sudo sed -i 's/#define PNG_SETJMP_SUPPORTED/#undef PNG_SETJMP_SUPPORTED/g' pnglibconf.h
	sudo sed -i 's/#define PNG_SIMPLIFIED_READ_SUPPORTED/#undef PNG_SIMPLIFIED_READ_SUPPORTED/g' pnglibconf.h
	sudo sed -i 's/#define PNG_SIMPLIFIED_WRITE_SUPPORTED/#undef PNG_SIMPLIFIED_WRITE_SUPPORTED/g' pnglibconf.h
	echo "compiling libpng to wasm"
        cd ~/image_decoding/libpng
        /opt/wasi-sdk/wasi-sdk-14.0/bin/clang --sysroot /opt/wasi-sdk/wasi-sdk-14.0/share/wasi-sysroot -o png.wasm png.c
	# add code to build the libpng LIBRARY to wasm THEN OUTSIDE OF THE SCRIPT use the big line of code from the txt file with libpng.wasm
fi

# Confirm completion
echo "done"
cd ~/image_decoding
