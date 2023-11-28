#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#ifdef ENABLE_SIMD
#include "decode_wasmsimd.h"
#else
#include "decode_wasm.h"
#endif

#include "uvwasi.h"
#include "uvwasi-rt.h"

#define BILLION 1000000000.0

/**
 * argv[1]: png image filename to decode
 * argv[2]: output csv file for timing information
 */
int main(int argc, char *argv[]) {
    if (argc < 3) {
		printf("Usage: %s <PNG image path> <output_text>\n", argv[0]);
		exit(1);
	}

    FILE *fp = fopen(argv[1], "rb");
	if (!fp) {
		printf("Invalid input image provided.\n");
		exit(1);
	}
    fseek(fp, 0, SEEK_END);
    long filelen = ftell(fp);
    rewind(fp);

    char *buffer = (char *)malloc(filelen * sizeof(char)); // Enough memory for the file
    fread(buffer, filelen, 1, fp); // Read in the entire file
    fclose(fp);

	FILE *out = fopen(argv[2], "a");
	if (!out) {
		printf("Invalid output file provided.\n");
		exit(1);
	}

    /* Initialize the Wasm runtime. */
    wasm_rt_init();
    /* Declare an instance of the `inst` module. */
#ifdef ENABLE_SIMD
    w2c_decode__wasmsimd inst = { 0 };
#else
    w2c_decode__wasm inst = { 0 };
#endif

    // uvwasi specific things
      uvwasi_t local_uvwasi_state = {0};

    struct w2c_wasi__snapshot__preview1 wasi_env = {
        .uvwasi = &local_uvwasi_state,
        .instance_memory = &inst.w2c_memory
    };

    uvwasi_options_t init_options;
    uvwasi_options_init(&init_options);

    //pass in standard descriptors
    init_options.in = 0;
    init_options.out = 1;
    init_options.err = 2;
    init_options.fd_table_size = 3;


    //no sandboxing enforced, binary has access to everything user does
    init_options.preopenc = 2;
    init_options.preopens = calloc(2, sizeof(uvwasi_preopen_t));

    init_options.preopens[0].mapped_path = "/";
    init_options.preopens[0].real_path = "/";
    init_options.preopens[1].mapped_path = "./";
    init_options.preopens[1].real_path = ".";

    init_options.allocator = NULL;

    uvwasi_errno_t ret = uvwasi_init(&local_uvwasi_state, &init_options);

    if (ret != UVWASI_ESUCCESS) {
        printf("uvwasi_init failed with error %d\n", ret);
        exit(1);
    }

    /* Construct the module instance. */
#ifdef ENABLE_SIMD
    wasm2c_decode__wasmsimd_instantiate(&inst, &wasi_env);
    wasm_rt_memory_t* mem = w2c_decode__wasmsimd_memory(&inst);
#else
    wasm2c_decode__wasm_instantiate(&inst, &wasi_env);
    wasm_rt_memory_t* mem = w2c_decode__wasm_memory(&inst);
#endif

    if (mem->size < filelen) {
        fprintf(stderr, "File too big (%zu) for WASM memory (%lu) \n", filelen, mem->size);
        goto EXIT;
    }

    // copy over data to WASM sandbox
#ifdef ENABLE_SIMD
    u32 png_file = w2c_decode__wasmsimd_malloc(&inst, filelen);
#else
    u32 png_file = w2c_decode__wasm_malloc(&inst, filelen);
#endif

    // NOTE: dst is a pointer into the linear memory
    memcpy(&(mem->data[png_file]), buffer, filelen);

    struct timespec start, end;
	double dt = 1.0;


    clock_gettime(CLOCK_REALTIME, &start);
#ifdef ENABLE_SIMD
    int status = w2c_decode__wasmsimd_png_decode(&inst, png_file, filelen);
#else
    int status = w2c_decode__wasm_png_decode(&inst, png_file, filelen);
#endif
    clock_gettime(CLOCK_REALTIME, &end);

    dt = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / BILLION;

    printf("time: %f\n", dt);
    fprintf(out, "%f\n", dt);

EXIT:
    fclose(out);
    /* Free the inst module. */
#ifdef ENABLE_SIMD
    wasm2c_decode__wasmsimd_free(&inst);
#else
    wasm2c_decode__wasm_free(&inst);
#endif
    uvwasi_destroy(&local_uvwasi_state);
    /* Free the Wasm runtime state. */
    wasm_rt_free();
    return 0;
}