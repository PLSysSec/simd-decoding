#!/bin/bash
set -e

UVWASI_PATH=/home/wrv/research/wasmperf/uvwasi-0.0.19

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
clang -O2 -static -Ilibpng_native/include/ -Llibpng_native/lib -o out/decode_native main_no_io_native.c decode_no_io.c -lpng16 -lz -lm

#echo " -- running native"
#out/decode_native images/large.png results/TEST.txt

echo "[X] Building NATIVE with SIMD"
clang -O2 -static -Ilibpng_nativesimd/include/ -I${SIMDE_PATH}/simde/wasm -Llibpng_nativesimd/lib -o out/decode_nativesimd main_no_io_native.c decode_no_io.c -lpng16 -mavx  -lz -lm

#echo " -- running native simd"
#out/decode_nativesimd images/large.png results/TEST.txt

echo "[X] Building WASM with NO SIMD"

#echo "compiling decode_no_io.c to WASM..."

${WASI_SDK_PATH}/bin/clang -O2 --sysroot ${WASI_SDK_PATH}/share/wasi-sysroot -Ilibpng_wasm/include/ -Llibpng_wasm/lib \
-Wl,--export=malloc,--export=png_decode -Wl,--no-entry -Wl,--growable-table -Wl,--stack-first -Wl,-z,stack-size=1048576 \
-mexec-model=reactor \
-Izlib_wasm/include/ -Lzlib_wasm/lib -o out/decode_wasm.wasm \
decode_no_io.c -lpng16 -lz

#echo " -- compiling decode.wasm to WAT..."
${WASM2C_PATH}/bin/wasm2wat -o out/decode_wasm.wat out/decode_wasm.wasm

#echo " -- compiling decode.wasm to C..."

${WASM2C_PATH}/bin/wasm2c -o out/decode_wasm.c out/decode_wasm.wasm

#echo " -- compiling modified decode_no_io.c to native..."

clang -O2 \
-o out/decode_wasm \
-I${WASM2C_PATH}/include \
-I${SIMDE_PATH} \
-Iout \
main_no_io_wasm.c \
out/decode_wasm.c \
${WASM2C_PATH}/share/wabt/wasm2c/wasm-rt-impl.c \
uvwasi-rt.c ${UVWASI_PATH}/out/cmake/libuvwasi_a.a ${UVWASI_PATH}/out/cmake/_deps/libuv-build/libuv_a.a -I${UVWASI_PATH}/include/ \
-lm

#echo " -- running wasm"
#out/decode_wasm images/large.png results/TEST.txt


echo "[X] Building WASM with SIMD"

#echo "compiling decode_no_io.c to WASMSIMD..."

${WASI_SDK_PATH}/bin/clang -O2 --sysroot ${WASI_SDK_PATH}/share/wasi-sysroot \
-Wl,--export=malloc,--export=png_decode -Wl,--no-entry -Wl,--growable-table -Wl,--stack-first -Wl,-z,stack-size=1048576 \
-mexec-model=reactor \
-Ilibpng_wasmsimd/include/ -Llibpng_wasmsimd/lib -Izlib_wasm/include/ -Lzlib_wasm/lib -o out/decode_wasmsimd.wasm \
decode_no_io.c -lpng16 -msimd128 -lz

#echo " -- compiling decode.wasm to WAT..."
${WASM2C_PATH}/bin/wasm2wat -o out/decode_wasmsimd.wat out/decode_wasmsimd.wasm

#echo " -- compiling decode.wasm to C..."

${WASM2C_PATH}/bin/wasm2c -o out/decode_wasmsimd.c out/decode_wasmsimd.wasm

#echo " -- compiling modified decode_no_io.c to native..."

clang -O2 -o out/decode_wasmsimd -I${WASM2C_PATH}/include -I${SIMDE_PATH} -Iout \
main_no_io_wasm.c out/decode_wasmsimd.c ${WASM2C_PATH}/share/wabt/wasm2c/wasm-rt-impl.c \
uvwasi-rt.c ${UVWASI_PATH}/out/cmake/libuvwasi_a.a ${UVWASI_PATH}/out/cmake/_deps/libuv-build/libuv_a.a -I${UVWASI_PATH}/include/ \
-lm -mavx -DENABLE_SIMD

#echo " -- running wasm"
#out/decode_wasmsimd images/large.png results/TEST.txt


echo "done"


