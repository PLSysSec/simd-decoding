# simd-decoding
This repository contains files necessary for testing a simple image decoding operation using `libpng` with SIMD instructions when compiled to WebAssembly. Note that this build uses wasi-sdk version 14.0, WASM-Micro-Runtime (WAMR), and WebAssmebly Binary Toolkit (WABT). Additionally, note that `libz` must be installed for `libpng` to build. 
The `build.sh` script provides a method for building the `libpng` library with and without SIMD instructions and with a native or WASM target. For the WebAssembly target, `zlib` must be built to WASM before building the `libpng` library. This is dones by using:<br />

```shell
export PATH=${WASI_SDK_PATH}/bin:$PATH
export PATH=${WASI_SDK_PATH}/bin/ranlib:$PATH
cd ${ZLIB_PATH}
CC=${WASI_SDK_PATH}/bin/clang ./configure --prefix=${WASI_SDK_PATH}/share/sysroot
make && make install
```

The `wasm_decode.sh` script compiles a `decode.c` file to WebAssembly to be executed with WAMR's iwasm VM Core (This script should only be used when working with the WASM target). The 'full_test.sh' script performs a test of execution speed for the built libpng library.
