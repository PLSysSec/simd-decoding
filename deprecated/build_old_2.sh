#!/bin/bash
set -e

help() {
	echo "Configure the libpng library for the image decoding algorithm."
	echo 
	echo "Syntax: bash build.sh [-h|s|w]"
	echo "options:"
	echo "h    Print this help menu."
	echo "s    Build with sse enabled."
	echo "w    Disable relavant libpng features for WASM compilation."
	echo
}

edit_libpngconf() {
	echo "editing libpngconf.h..."
	make pnglibconf.h
	sed -i 's/#define PNG_SETJMP_SUPPORTED/#undef PNG_SETJMP_SUPPORTED/g' pnglibconf.h
	sed -i 's/#define PNG_SIMPLIFIED_READ_SUPPORTED/#undef PNG_SIMPLIFIED_READ_SUPPORTED/g' pnglibconf.h
	sed -i 's/#define PNG_SIMPLIFIED_WRITE_SUPPORTED/#undef PNG_SIMPLIFIED_WRITE_SUPPORTED/g' pnglibconf.h
}

# Enable and disable SSE during build
# Prepare for WASM usage in compilation
while getopts "hsw" OPTION
do
	case $OPTION in
		h) help
				exit;;
		s) sse=true
				echo "sse enabled...";;
		w) wasm=true
				echo "wasm compilation enabled...";;
	esac
done

# Build the libpng library
echo "running make clean..."
cd ./libpng && make clean > /dev/null

if [[ "$sse" = true && "$wasm" = true ]]; then # SSE and WASM
	CFLAGS="-DPNG_NO_SETJMP -D_WASI_EMULATED_SIGNAL -ferror-limit=0" \
	LIBS=-lwasi-emulated-signal \
	LDFLAGS=-L/opt/wasi-sdk/wasi-sdk-14.0/share/wasi-sysroot/lib \
	CC=/opt/wasi-sdk/wasi-sdk-14.0/bin/clang \
	./configure \
	--with-sysroot=/opt/wasi-sdk/wasi-sdk-14.0/share/wasi-sysroot \
	--enable-intel-sse=yes --host=wasm32 \
	--prefix=/opt/wasi-sdk/wasi-sdk-14.0/share/wasi-sysroot

	edit_libpngconf

	CC=/opt/wasi-sdk/wasi-sdk-14.0/bin/clang \
	CFLAGS="--sysroot /opt/wasi-sdk/wasi-sdk-14.0/share/wasi-sysroot" \
	LD=/opt/wasi-sdk/wasi-sdk-14.0/bin/wasm-ld \
	LDFLAGS="-Wl,--export-all -Wl,--growable-table" make 

	make install 
elif [[ "$sse" = true ]]; then # SSE and no WASM
	./configure --enable-intel-sse=yes 

	make

	sudo make install
elif [[ "$wasm" = true ]]; then # no SSE and WASM
	CFLAGS="-DPNG_NO_SETJMP -D_WASI_EMULATED_SIGNAL" \
	LIBS=-lwasi-emulated-signal \
	LDFLAGS="-L/opt/rlbox_wasm2c_sandbox/build/_deps/wasiclang-src/share/wasi-sysroot/lib \
	 -Wl,--no-entry -Wl,--export-all -Wl,--growable-table $*" \
	LD=/opt/wasi-sdk/wasi-sdk-14.0/bin/wasm-ld \
	LDLIBS=/opt/rlbox_wasm2c_sandbox/c_src/wasm2c_sandbox_wrapper.o
	CC=/opt/wasi-sdk/wasi-sdk-14.0/bin/clang \
	./configure \
	--with-sysroot=/opt/wasi-sdk/wasi-sdk-14.0/share/wasi-sysroot \
	--enable-intel-sse=no --host=wasm32 \
	--prefix=/opt/wasi-sdk/wasi-sdk-14.0/share/wasi-sysroot\

	# CC=/opt/rlbox_wasm2c_sandbox/build/_deps/wasiclang-src/bin/clang \
	# CXX=/opt/rlbox_wasm2c_sandbox/build/_deps/wasiclang-src/bin/clang++ \
	# CFLAGS="--sysroot /opt/rlbox_wasm2c_sandbox/build/_deps/wasiclang-src/share/wasi-sysroot -DPNG_NO_SETJMP" \
	# LD=/opt/rlbox_wasm2c_sandbox/build/_deps/wasiclang-src/bin/wasm-ld \
	# LDFLAGS="-Wl,--export-all -Wl,--growable-table -L/opt/rlbox_wasm2c_sandbox/build/_deps/wasiclang-src/share/wasi-sysroot/lib" \
	# ./configure \
	# --host=wasm32 \
	# --with-sysroot=/opt/rlbox_wasm2c_sandbox/build/_deps/wasiclang-src/share/wasi-sysroot/ \
	# --prefix=/opt/rlbox_wasm2c_sandbox/build/_deps/wasiclang-src/share/wasi-sysroot/
				
	edit_libpngconf
	make
	make install 
else # no SSE and no WASM
	echo "configuring without sse and with SETJMP..."
	./configure --enable-intel-sse=no

	make
	
	sudo make install
fi

# Extra steps for wasm 
if [[ "$wasm" = true ]]; then
	
	# Write decode.c to decode.wasm with SIMDe
	echo "compiling decode.c to WASM..."
  cd .. 
	LDFLAGS="-Wl,--export-all -Wl,--growable-table"
	/opt/wasi-sdk/wasi-sdk-14.0/bin/clang \
	--sysroot /opt/wasi-sdk/wasi-sdk-14.0/share/wasi-sysroot \
	-I/opt/wasi-sdk/wasi-sdk-14.0/share/wasi-sysroot/include/libpng16 \
	-I/opt/simde-no-tests/wasm \
	-L/opt/wasi-sdk/wasi-sdk-14.0/share/wasi-sysroot/lib \
	-o decode.wasm decode.c -lpng16 -lz

# 	# Write libpng to a libpng.wasm file
# 	echo "exporting libpng to .wasm"
# 	cd /opt/wasi-sdk/wasi-sdk-14.0/share/wasi-sysroot/lib

# 	if [[ "$sse" = true ]]; then
# 		/opt/wasi-sdk/wasi-sdk-14.0/bin/clang \
# 		-o libpng.wasm libpng.a \
# 		-Wl,--export-all \
# 		-Wl,--no-entry \
# 		-nostdlib -msimd128
# 	else
# 		/opt/wasi-sdk/wasi-sdk-14.0/bin/clang \
# 		-o libpng.wasm libpng.a \
# 		-Wl,--export-all \
# 		-Wl,--no-entry \
# 		-nostdlib 
# 	fi
fi 

# Confirm completion
echo "done"
