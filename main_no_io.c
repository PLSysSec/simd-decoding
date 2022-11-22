#include <stdio.h>
#include <stdlib.h>

#ifdef ENABLE_SIMD
#include <decode_wasmsimd.h>
#else
#include <decode_wasm.h>
#endif

/**
 * argv[1]: png image filename to decode
 * argv[2]: output csv file for timing information
 */
int main(int argc, char *argv[]) {
    if (argc < 3) {
		printf("Usage: %s <PNG image path> <output_text>\n", argv[0]);
		exit(1);
	}

    wasm2c_sandbox_funcs_t sbx_details = get_wasm2c_sandbox_info();
    sbx_details.wasm_rt_sys_init();

    int max_wasm_page = 0;
    wasm2c_sandbox_t* sbx_instance = (wasm2c_sandbox_t*) sbx_details.create_wasm2c_sandbox(max_wasm_page);

    wasm_rt_memory_t* mem = sbx_details.lookup_wasm2c_nonfunc_export(sbx_instance, "w2c_memory");

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

    // copy over data to WASM sandbox
    u32 png_file = w2c_malloc(sbx_instance, filelen);

    // NOTE: dst is a pointer into the linear memory
    memcpy(&(mem->data[png_file]), buffer, filelen);

    double dt = w2c_timed_decode(sbx_instance, png_file, filelen);

    printf("time: %f\n", dt);
    fprintf(out, "%f\n", dt);
    fclose(out);
    

    sbx_details.destroy_wasm2c_sandbox(sbx_instance);
    return 0;
}