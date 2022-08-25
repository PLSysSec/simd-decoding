#!/bin/bash
set -e

help() {
	echo "Configure decode.c and WAMR compiler with libpng WASM target."
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
  
echo "compiling decode.c to WASM..."
if [[ "$simd" = true ]]; then 
	CFLAGS="-O3 -fopenmp-simd" \
	LDFLAGS="-Wl,--export-all -Wl,--growable-table" \
	${WASI_SDK_PATH}/bin/clang \
	--sysroot ${WASI_SDK_PATH}/share/wasi-sysroot \
	-I${WASI_SDK_PATH}/share/wasi-sysroot/include/libpng16 \
	-I${SIMDE_PATH}/wasm \
	-L${WASI_SDK_PATH}/share/wasi-sysroot/lib \
	-o out/decode_simd.wasm \
	decode.c \
	-lpng16 -lz 
else 
	LDFLAGS="-Wl,--export-all -Wl,--growable-table" \
	${WASI_SDK_PATH}/bin/clang \
	--sysroot ${WASI_SDK_PATH}/share/wasi-sysroot \
	-I${WASI_SDK_PATH}/share/wasi-sysroot/include/libpng16 \
	-L${WASI_SDK_PATH}/share/wasi-sysroot/lib \
	-o out/decode_no_simd.wasm \
	decode.c \
	-lpng16 -lz 
fi 

# Extraneous step - only for checking WASM code
echo "converting .wasm to .wat..."
if [[ "$simd" = true ]]; then
	${WABT_PATH}/build/wasm2wat -o out/decode_simd.wat out/decode_simd.wasm
else 
	${WABT_PATH}/build/wasm2wat -o out/decode_nosimd.wat out/decode_no_simd.wasm
fi

echo "rebuilding WAMR..."
if [[ "$simd" = true ]]; then 
	cd ${WAMR_PATH}/wamr-compiler/build 
	cmake .. -DWAMR_BUILD_SIMD=1
	make 
	cd ${SCRIPT_PATH}
else 
	cd ${WAMR_PATH}/wamr-compiler/build 
	cmake .. -DWAMR_BUILD_SIMD=0
	make 
	cd ${SCRIPT_PATH}
fi

echo "compiling to AOT with wamrc..."
if [[ "$simd" = true ]]; then 
	${WAMR_PATH}/wamr-compiler/build/wamrc \
	-o out/decode_simd.aot \
	out/decode_simd.wasm
else 
	${WAMR_PATH}/wamr-compiler/build/wamrc \
	--disable-simd \
	-o out/decode_nosimd.aot \
	out/decode_no_simd.wasm
fi 

echo "done"
