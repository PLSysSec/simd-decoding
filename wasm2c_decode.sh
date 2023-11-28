#!/bin/bash
set -e

help() {
	echo "Compile decode.c to wasm and re-compile back to c."
	echo
	echo "Syntax: bash wasm_decode.sh [-h|s]"
	echo "options:"
	echo "h    Print this help menu."
	echo "s    Run with WASM SIMD128 instructions enabled for libpng library"
	echo
}

while getopts "hs" OPTION
do
	case $OPTION in
		h) help
				exit;;
		s) simd=true
				echo "simd enabled...";;
	esac
done

SCRIPT=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "$SCRIPT")

# Assume SIMD disabled for now; TODO add simd functionality

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

echo "compiling decode.c to WASM..."

LDFLAGS="-Wl,--export-all -Wl,--growable-table" \
${WASI_SDK_PATH}/bin/clang \
--sysroot ${WASI_SDK_PATH}/share/wasi-sysroot \
-I${WASI_SDK_PATH}/share/wasi-sysroot/include/libpng16 \
-L${WASI_SDK_PATH}/share/wasi-sysroot/lib \
-o out/decode.wasm \
decode.c \
-lpng16 -lz

echo "compiling decode.wasm to C..."

${WASM2C_PATH}/build/wasm2c \
-o out/decode_mod.c \
out/decode.wasm

echo "compiling modified decode.c to native..."

gcc \
-o out/main \
-I${WASM2C_PATH}/wasm2c \
-I${SIMDE_PATH} \
-Iout \
main.c \
out/decode_mod.c \
${WASM2C_PATH}/wasm2c/wasm-rt-impl.c \
${WASM2C_PATH}/wasm2c/wasm-rt-os-unix.c \
${WASM2C_PATH}/wasm2c/wasm-rt-os-win.c \
${WASM2C_PATH}/wasm2c/wasm-rt-wasi.c \
-lm

echo "TEST: running native code"

# Non-functional due to problems with wasm2c system calls
out/main images/large.png results/TEST.txt

echo "done"