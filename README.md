# simd-decoding

## Overview ##
This repository contains files necessary for testing a simple image decoding operation using `libpng` with SIMD instructions when compiled to WebAssembly. Note that this build uses wasi-sdk version 14.0, WASM-Micro-Runtime (WAMR), and WebAssmebly Binary Toolkit (WABT). Additionally, note that `libz` must be installed for `libpng` to build. 
The `build.sh` script provides a method for building the `libpng` library with and without SIMD instructions and with a native or WASM target. For the WebAssembly target, `zlib` must be built to WASM before building the `libpng` library. This is dones by using:<br />

```shell
export PATH=${WASI_SDK_PATH}/bin:$PATH
export PATH=${WASI_SDK_PATH}/bin/ranlib:$PATH
cd ${ZLIB_PATH}
CC=${WASI_SDK_PATH}/bin/clang ./configure --prefix=${WASI_SDK_PATH}/share/wasi-sysroot
make && make install
```

The `wasm_decode.sh` script compiles a `decode.c` file to WebAssembly to be executed with WAMR's iwasm VM Core (This script should only be used when working with the WASM target). The 'full_test.sh' script performs a test of execution speed for the built libpng library.

## Benchmark Environment Setup ##

To setup the benchmarking environment, we first disable CPU frequency scaling and set the system to performance mode (using `cpufrequtils`):

```shell
echo GOVERNOR="performance" >> /etc/default/cpufrequtils
sudo systemctl disable ondemand
```

To set CPU isolation and shielding, we run

```shell
sudo nano /etc/default/grub
```

and add `isolcpus=1` to `GRUB_CMDLINE_LINUX_DEFAULT`. Then, to set CPU shielding, 

```shell
sudo cset shield -c 1 -k on
```

## Testing ##

There are four tests that can be run, depending on whether SIMD instructions are enabled or disabled and whether we are building to a native or WASM target. Each test can be run as follows:

### Native Target with SSE Instructions ###

```shell
bash build.sh -s
taskset -c 1 bash full_test.sh -s
```

### Native Target without SSE Instructions ###

```shell
bash build.sh
taskset -c 1 bash full_test.sh
```

### WASM Target with SIMD128 Instructions ###

```shell
bash build.sh -s -w
bash wasm_decode.sh -s
taskset -c 1 bash full_test.sh -s -w
```

### WASM Target without SIMD128 Instructions ###

```shell
bash build.sh -w
bash wasm_decode.sh 
taskset -c 1 bash full_test.sh -w
```
