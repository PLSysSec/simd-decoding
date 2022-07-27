#!/bin/bash
set -e

/opt/wasi-sdk/wasi-sdk-14.0/bin/clang \
--sysroot /opt/wasi-sdk/wasi-sdk-14.0/share/wasi-sysroot \
-I/opt/simde-no-tests/wasm \
-o test.wasm \
test.c

/opt/wabt/build/wasm2wat -o test.wat test.wasm