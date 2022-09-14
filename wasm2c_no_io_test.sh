
if [ -z "$WASI_SDK_PATH" ]; then 
	echo "Set WASI_SDK_PATH before running and run the following:"
	echo "  export PATH=\${WASI_SDK_PATH}/bin:\$PATH"
	echo "  export PATH=\${WASI_SDK_PATH}/bin/ranlib:\$PATH"
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

PATH=${WASI_SDK_PATH}/bin:$PATH
PATH=${WASI_SDK_PATH}/bin/ranlib:$PATH

N=20
###########################################
echo "Testing WASMSIMD Wasm2c"

echo "[X] Building WASMSIMD libpng"
# Build the WASMSIMD version of libpng
simd=true wasm=true ./build.sh

echo "[X] Building WASMSIMD libpng test program"
# Build the WASM2C test program
./wasm2c_decode_no_io.sh

echo "[X] Running WASMSIMD test program for $N times"

# Clear out previous results
echo "" > results/wasm2c_with_simd.csv

# Non-functional due to problems with wasm2c system calls
for i in $(seq 1 $N)
do
	out/main images/large.png results/wasm2c_with_simd.csv
done

echo "[X] Analyzing WASMSIMD results"
python3 stat_analysis.py results/wasm2c_with_simd.csv

###########################################
echo "Testing WASM Wasm2c"

echo "[X] Building WASM libpng"
# Build the WASM version of libpng
wasm=true ./build.sh

echo "[X] Building WASM libpng test program"
# Build the WASM2C test program
./wasm2c_decode_no_io.sh

echo "[X] Running WASM test program for $N times"

# Clear out previous results
echo "" > results/wasm2c_no_simd.csv

# Non-functional due to problems with wasm2c system calls
for i in $(seq 1 $N)
do
	out/main images/large.png results/wasm2c_no_simd.csv
done

echo "[X] Analyzing WASMSIMD results"
python3 stat_analysis.py results/wasm2c_no_simd.csv

###########################################
echo "Done"
