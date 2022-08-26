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

# Compile decode.c to wasm 
LDFLAGS="-Wl,--export-all -Wl,--growable-table" \
${WASI_SDK_PATH}/bin/clang \
--sysroot ${WASI_SDK_PATH}/share/wasi-sysroot \
-I${WASI_SDK_PATH}/share/wasi-sysroot/include/libpng16 \
-L${WASI_SDK_PATH}/share/wasi-sysroot/lib \
-o out/decode.wasm \
decode.c \
-lpng16 -lz 

# Compile decode.wasm to c