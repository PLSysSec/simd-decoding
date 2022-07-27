#!/bin/bash

Help() {
echo "Compile decode.c and perform measurements."
echo "NOTE: USE SAME OPTIONS AS PREVIOUS build.sh RUN."
echo
echo "Syntax: bash build.sh [-h|s|w]"
echo "options:"
echo "h    Print this help menu."
echo "s    Compile with sse enabled."
echo "w    Compile to WASM."
echo
}

# Enable and disable SSE during build
# Prepare for WASM usage in compilation
while getopts "hsw" OPTION
do
    case $OPTION in
        h) Help
           exit;;
        s) sse=true
           echo "sse enabled...";;
        w) wasm=true
           echo "wasm enabled...";;
    esac
done

if [[ "$wasm" = true ]]; then # WASM and SSE

/opt/wasi-sdk/wasi-sdk-14.0/bin/clang \
--sysroot /opt/wasi-sdk/wasi-sdk-14.0/share/wasi-sysroot -Wl,--export-all \
test.c -o test.wasm

# elif [[ "$wasm" = true ]]; then # WASM and no SSE
# CC=/opt/wasi-sdk/wasi-sdk-14.0/bin/clang \
# --sysroot=/opt/wasi-sdk/wasi-sdk-14.0/share/wasi-sysroot
# CC decode.c -o decode.wasm

else # NO WASM 
    gcc -I/usr/local/include/libpng16 -L/usr/local/lib -o decode decode.c -lpng16
    hyperfine -w 20 -r 50 './decode large.png'
fi