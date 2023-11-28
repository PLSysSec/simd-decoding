cd ./libpng

make clean > /dev/null
echo "Building Native version of libpng"
./configure --enable-intel-sse=no \
--prefix=${curdir}/libpng_native

make
make install

cd ..