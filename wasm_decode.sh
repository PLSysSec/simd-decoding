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
  
echo "compiling decode.c to WASM..."
if [[ "$simd" = true ]]; then 
	CFLAGS="-O3 -fopenmp-simd" \
	LDFLAGS="-Wl,--export-all -Wl,--growable-table" \
	/opt/wasi-sdk/wasi-sdk-14.0/bin/clang \
	--sysroot /opt/wasi-sdk/wasi-sdk-14.0/share/wasi-sysroot \
	-I/opt/wasi-sdk/wasi-sdk-14.0/share/wasi-sysroot/include/libpng16 \
	-I/opt/simde-no-tests/wasm \
	-L/opt/wasi-sdk/wasi-sdk-14.0/share/wasi-sysroot/lib \
	-o decode_simd.wasm \
	decode_simd.c \
	-lpng16 -lz 
else 
	LDFLAGS="-Wl,--export-all -Wl,--growable-table" \
	/opt/wasi-sdk/wasi-sdk-14.0/bin/clang \
	--sysroot /opt/wasi-sdk/wasi-sdk-14.0/share/wasi-sysroot \
	-I/opt/wasi-sdk/wasi-sdk-14.0/share/wasi-sysroot/include/libpng16 \
	-L/opt/wasi-sdk/wasi-sdk-14.0/share/wasi-sysroot/lib \
	-o decode_no_simd.wasm \
	decode_no_simd.c \
	-lpng16 -lz 
fi 

# Extraneous step - only for checking WASM code
echo "converting .wasm to .wat..."
if [[ "$simd" = true ]]; then
	/opt/wabt/build/wasm2wat -o decode_simd.wat decode_simd.wasm
else 
	/opt/wabt/build/wasm2wat -o decode_nosimd.wat decode_no_simd.wasm
fi

echo "rebuilding WAMR..."
if [[ "$simd" = true ]]; then 
	cd /opt/wasm-micro-runtime/wamr-compiler/build 
	sudo cmake .. -DWAMR_BUILD_SIMD=1
	sudo make 
	cd /home/jgoldman/image_decoding
else 
	cd /opt/wasm-micro-runtime/wamr-compiler/build 
	sudo cmake .. -DWAMR_BUILD_SIMD=0
	sudo make 
	cd /home/jgoldman/image_decoding
fi

echo "compiling to AOT with wamrc..."
if [[ "$simd" = true ]]; then 
	/opt/wasm-micro-runtime/wamr-compiler/build/wamrc \
	-o decode_simd.aot \
	decode_simd.wasm
else 
	/opt/wasm-micro-runtime/wamr-compiler/build/wamrc \
	--disable-simd \
	-o decode_nosimd.aot \
	decode_no_simd.wasm
fi 

echo "done"
