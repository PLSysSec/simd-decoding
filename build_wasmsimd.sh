
edit_libpngconf() {
	echo "editing libpngconf.h..."
	make pnglibconf.h
	sed -i 's/#define PNG_SETJMP_SUPPORTED/#undef PNG_SETJMP_SUPPORTED/g' pnglibconf.h
	sed -i 's/#define PNG_SIMPLIFIED_READ_SUPPORTED/#undef PNG_SIMPLIFIED_READ_SUPPORTED/g' pnglibconf.h
	sed -i 's/#define PNG_SIMPLIFIED_WRITE_SUPPORTED/#undef PNG_SIMPLIFIED_WRITE_SUPPORTED/g' pnglibconf.h
}

cd ./libpng

make clean > /dev/null
echo "Building WASMSIMD version of libpng"
CFLAGS="-DPNG_NO_SETJMP \
	-D_WASI_EMULATED_SIGNAL \
	-O2 \
	-msimd128" \
LIBS=-lwasi-emulated-signal \
CPPFLAGS="-I${SIMDE_PATH}/simde/wasm" \
LDFLAGS="-L${WASI_SDK_PATH}/share/wasi-sysroot/lib \
	-Wl,--no-entry \
	-Wl,--export-all \
	-Wl,--growable-table $*" \
LD=${WASI_SDK_PATH}/bin/wasm-ld \
CC=${WASI_SDK_PATH}/bin/clang \
AR=${WASI_SDK_PATH}/bin/ar \
STRIP=${WASI_SDK_PATH}/bin/strip \
RANLIB=${WASI_SDK_PATH}/bin/ranlib \
./configure \
--with-sysroot=${WASI_SDK_PATH}/share/wasi-sysroot \
--enable-intel-sse=yes \
--host=wasm32 \
--prefix=${curdir}/libpng_wasmsimd

edit_libpngconf
makefile_add_simd
make
make install

cd ..