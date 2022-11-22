#!/bin/bash
set -e

help() {
	echo "Build libpng to the appropriate target."
	echo 
	echo "Syntax: bash build.sh [-h|s|w]"
	echo "options:"
	echo "h    Print this help menu."
	echo "s    Build with SIMD instructions."
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

makefile_add_simd() {
	sed -i 's/-O2/-O3 -msimd128/g' Makefile
}

# Check environment variables are set
if [ -z "$WASI_SDK_PATH" ]; then 
	echo "Set WASI_SDK_PATH before running and run the following:"
	echo "  export PATH=\${WASI_SDK_PATH}/bin:\$PATH"
	echo "  export PATH=\${WASI_SDK_PATH}/bin/ranlib:\$PATH"
	exit 1
fi 

if [ -z "$SIMDE_PATH" ]; then 
	echo "Set SIMDE_PATH before running"
	exit 1
fi 

# Enable and disable SIMD during build
# Prepare for WASM usage in compilation
while getopts "hsw" OPTION
do
	case $OPTION in
		h) help
				exit;;
		s) simd=true
				echo "SIMD enabled...";;
		w) wasm=true
				echo "building to WASM target...";;
	esac
done

curdir=$(pwd)

# Build the libpng library
echo "running make clean..."
cd ./libpng && make clean > /dev/null


make clean > /dev/null
echo "Building Native version of libpng"
./configure --enable-intel-sse=no \
--prefix=${curdir}/libpng_native

make
make install

make clean > /dev/null
echo "Building Native SIMD version of libpng"
./configure --enable-intel-sse=yes \
CPPFLAGS="-I${SIMDE_PATH}/simde/wasm" \
--prefix=${curdir}/libpng_nativesimd

make
make install

make clean > /dev/null
echo "Building WASM version of libpng"
CFLAGS="-DPNG_NO_SETJMP \
	-D_WASI_EMULATED_SIGNAL" \
LIBS=-lwasi-emulated-signal \
CPPFLAGS="-I${SIMDE_PATH}/simde/wasm" \
LDFLAGS="-L${WASI_SDK_PATH}/share/wasi-sysroot/lib \
	-Wl,--no-entry \
	-Wl,--export-all \
	-Wl,--growable-table $*" \
LD=${WASI_SDK_PATH}/bin/wasm-ld \
CC=${WASI_SDK_PATH}/bin/clang \
./configure \
--with-sysroot=${WASI_SDK_PATH}/share/wasi-sysroot \
--enable-intel-sse=no \
--host=wasm32 \
--prefix=${curdir}/libpng_wasm

edit_libpngconf
make
make install 

make clean > /dev/null
echo "Building WASMSIMD version of libpng"
CFLAGS="-DPNG_NO_SETJMP \
	-D_WASI_EMULATED_SIGNAL \
	-O3 \
	-msimd128" \
LIBS=-lwasi-emulated-signal \
CPPFLAGS="-I${SIMDE_PATH}/simde/wasm" \
LDFLAGS="-L${WASI_SDK_PATH}/share/wasi-sysroot/lib \
	-Wl,--no-entry \
	-Wl,--export-all \
	-Wl,--growable-table $*" \
LD=${WASI_SDK_PATH}/bin/wasm-ld \
CC=${WASI_SDK_PATH}/bin/clang \
./configure \
--with-sysroot=${WASI_SDK_PATH}/share/wasi-sysroot \
--enable-intel-sse=yes \
--host=wasm32 \
--prefix=${curdir}/libpng_wasmsimd

edit_libpngconf
makefile_add_simd
make
make install 

# Confirm completion
echo "done"
