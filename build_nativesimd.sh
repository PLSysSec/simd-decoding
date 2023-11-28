cd ./libpng


make clean > /dev/null
echo "Building Native SIMD version of libpng"
./configure --enable-intel-sse=yes \
CPPFLAGS="-I${SIMDE_PATH}/simde/wasm" \
--prefix=${curdir}/libpng_nativesimd

make
make install

cd ..