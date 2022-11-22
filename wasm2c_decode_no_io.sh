#!/bin/bash
set -e


SCRIPT=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "$SCRIPT")

if [ -z "$WASI_SDK_PATH" ]; then 
	echo "Set WASI_SDK_PATH before running"
	exit 1
fi 

if [ -z "$SIMDE_PATH" ]; then 
	echo "Set SIMDE_PATH before running"
	exit 1
fi 

if [ -z "$WASM2C_PATH" ]; then 
	echo "Set WASM2C_PATH before running"
	exit 1
fi 

mkdir -p out

echo "[X] Building NATIVE with NO SIMD"
#echo " -- compiling decode_no_io.c to native..."
gcc -Ilibpng_native/include/ -Llibpng_native/lib -o out/decode_native decode_no_io.c -lpng16

#echo " -- running native"
#out/decode_native images/large.png results/TEST.txt 

echo "[X] Building NATIVE with SIMD"
gcc -Ilibpng_nativesimd/include/ -I${SIMDE_PATH}/simde/wasm -Llibpng_nativesimd/lib -o out/decode_nativesimd decode_no_io.c -lpng16 -mavx

#echo " -- running native simd"
#out/decode_nativesimd images/large.png results/TEST.txt 

echo "[X] Building WASM with NO SIMD"

#echo "compiling decode_no_io.c to WASM..."

LDFLAGS="-Wl,--export-all -Wl,--no-entry -Wl,--growable-table -Wl,--stack-first -Wl,-z,stack-size=1048576" \
${WASI_SDK_PATH}/bin/clang --sysroot ${WASI_SDK_PATH}/share/wasi-sysroot -Ilibpng_wasm/include/ -Llibpng_wasm/lib \
-Izlib_wasm/include/ -Lzlib_wasm/lib -o out/decode_wasm.wasm \
decode_no_io.c -lpng16 -lz

#echo " -- compiling decode.wasm to WAT..."
${WASM2C_PATH}/build/wasm2wat -o out/decode_wasm.wat out/decode_wasm.wasm

#echo " -- compiling decode.wasm to C..."

${WASM2C_PATH}/build/wasm2c -o out/decode_wasm.c out/decode_wasm.wasm

#echo " -- compiling modified decode_no_io.c to native..."

gcc \
-o out/decode_wasm \
-I${WASM2C_PATH}/wasm2c \
-I${SIMDE_PATH} \
-Iout \
main_no_io.c \
out/decode_wasm.c \
${WASM2C_PATH}/wasm2c/wasm-rt-impl.c \
${WASM2C_PATH}/wasm2c/wasm-rt-os-unix.c \
${WASM2C_PATH}/wasm2c/wasm-rt-os-win.c \
${WASM2C_PATH}/wasm2c/wasm-rt-wasi.c \
-lm

#echo " -- running wasm"
#out/decode_wasm images/large.png results/TEST.txt


echo "[X] Building WASM with SIMD"

#echo "compiling decode_no_io.c to WASMSIMD..."

LDFLAGS="-Wl,--export-all -Wl,--no-entry -Wl,--growable-table -Wl,--stack-first -Wl,-z,stack-size=1048576" \
${WASI_SDK_PATH}/bin/clang --sysroot ${WASI_SDK_PATH}/share/wasi-sysroot \
-Ilibpng_wasmsimd/include/ -Llibpng_wasmsimd/lib -Izlib_wasm/include/ -Lzlib_wasm/lib -o out/decode_wasmsimd.wasm \
decode_no_io.c -lpng16 -msimd128 -lz

#echo " -- compiling decode.wasm to WAT..."
${WASM2C_PATH}/build/wasm2wat -o out/decode_wasmsimd.wat out/decode_wasmsimd.wasm

#echo " -- compiling decode.wasm to C..."

${WASM2C_PATH}/build/wasm2c -o out/decode_wasmsimd.c out/decode_wasmsimd.wasm

#echo " -- compiling modified decode_no_io.c to native..."

gcc \
-o out/decode_wasmsimd \
-I${WASM2C_PATH}/wasm2c \
-I${SIMDE_PATH} \
-Iout \
main_no_io.c \
out/decode_wasmsimd.c \
${WASM2C_PATH}/wasm2c/wasm-rt-impl.c \
${WASM2C_PATH}/wasm2c/wasm-rt-os-unix.c \
${WASM2C_PATH}/wasm2c/wasm-rt-os-win.c \
${WASM2C_PATH}/wasm2c/wasm-rt-wasi.c \
-lm -mavx \
-DENABLE_SIMD

#echo " -- running wasm"
#out/decode_wasmsimd images/large.png results/TEST.txt


echo "done"


