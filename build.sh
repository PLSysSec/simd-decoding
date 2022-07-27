#!/bin/bash
set -e

help() {
	echo "Build libpng to the appropriate target."
	echo 
	echo "Syntax: bash build.sh [-h|s|w]"
	echo "options:"
	echo "h    Print this help menu."
	echo "s    Build with sse enabled."
	echo "w    Build to WASM target."
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
				echo "SSE enabled...";;
		w) wasm=true
				echo "building to WASM target...";;
	esac
done

# Build the libpng library
echo "running make clean..."
cd ./libpng && make clean > /dev/null

if [[ "$sse" = true && "$wasm" = true ]]; then # SIMD instructions and WASM target
	CFLAGS="-DPNG_NO_SETJMP \
	 -D_WASI_EMULATED_SIGNAL \
	 -O3" \
	LIBS=-lwasi-emulated-signal \
	CPPFLAGS="-I/opt/simde-no-tests/wasm"
	LDFLAGS="-L/opt/wasi-sdk/wasi-sdk-14.0/share/wasi-sysroot/lib \
	 -Wl,--no-entry \
	 -Wl,--export-all \
	 -Wl,--growable-table $*" \
	LD=/opt/wasi-sdk/wasi-sdk-14.0/bin/wasm-ld \
	CC=/opt/wasi-sdk/wasi-sdk-14.0/bin/clang \
	./configure \
	--with-sysroot=/opt/wasi-sdk/wasi-sdk-14.0/share/wasi-sysroot \
	--enable-intel-sse=yes \
	--host=wasm32 \
	--prefix=/opt/wasi-sdk/wasi-sdk-14.0/share/wasi-sysroot

	edit_libpngconf
	make
	make install 
elif [[ "$sse" = true ]]; then # SSE and native target
	./configure --enable-intel-sse=yes 

	make
	sudo make install
elif [[ "$wasm" = true ]]; then # no SIMD and WASM target
	CFLAGS="-DPNG_NO_SETJMP \
	 -D_WASI_EMULATED_SIGNAL" \
	LIBS=-lwasi-emulated-signal \
	LDFLAGS="-L/opt/wasi-sdk/wasi-sdk-14.0/share/wasi-sysroot/lib \
	 -Wl,--no-entry \
	 -Wl,--export-all \
	 -Wl,--growable-table $*" \
	LD=/opt/wasi-sdk/wasi-sdk-14.0/bin/wasm-ld \
	CC=/opt/wasi-sdk/wasi-sdk-14.0/bin/clang \
	./configure \
	--with-sysroot=/opt/wasi-sdk/wasi-sdk-14.0/share/wasi-sysroot \
	--enable-intel-sse=no \
	--host=wasm32 \
	--prefix=/opt/wasi-sdk/wasi-sdk-14.0/share/wasi-sysroot

	edit_libpngconf
	make
	make install 
else # no SSE and native target
	./configure --enable-intel-sse=no

	make
	sudo make install
fi

# Confirm completion
echo "done"
