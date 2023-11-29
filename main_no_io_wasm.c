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
#define PAGE_SIZE 65536

/**
 * argv[1]: png image filename to decode
 * argv[2]: output csv file for timing information
 */
int main(int argc, char *argv[]) {
  const char* input_file = NULL;
  const char* output_time_file = NULL;
  const char* output_image_file = NULL;

  if (argc < 3) {
    printf("Not enough arguments provided.\n");
    printf("Usage: ./%s <image> <output_time> <(optional) output_image> \n", argv[0]);
    return -1;
  }

  input_file = argv[1];
  output_time_file = argv[2];

  if (argc > 3) {
    output_image_file = argv[3];
  }

  FILE *fp = fopen(input_file, "rb");
  if (!fp) {
    printf("Invalid input image provided: %s.\n", input_file);
    return -1;
  }
  fseek(fp, 0, SEEK_END);
  long filelen = ftell(fp);
  rewind(fp);

  unsigned char *buffer = (unsigned char *)malloc(filelen * sizeof(unsigned char)); // Enough memory for the file
  fread(buffer, filelen, 1, fp); // Read in the entire file
  fclose(fp);

  FILE *out = fopen(output_time_file, "a");
  if (!out) {
    printf("Invalid output file provided: %s.\n", output_time_file);
    return -1;
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
    // Grow memory to handle file
    uint64_t delta = ((filelen - mem->size)/PAGE_SIZE)+1;
    uint64_t old_pages = wasm_rt_grow_memory(mem, delta);
    fprintf(stderr, "File too big (%zu) for WASM memory (%lu)\n", filelen, mem->size);
    fprintf(stderr, "Grew memory of size %lu by %lu pages\n", old_pages, delta);
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

#ifdef ENABLE_SIMD
  u32 row_pointers_ptr = w2c_decode__wasmsimd_malloc(&inst, sizeof(u32));
  u32 height_ptr = w2c_decode__wasmsimd_malloc(&inst, sizeof(u32));
  u32 row_bytes_ptr = w2c_decode__wasmsimd_malloc(&inst, sizeof(u32));
#else
  u32 row_pointers_ptr = w2c_decode__wasm_malloc(&inst, sizeof(u32));
  u32 height_ptr = w2c_decode__wasm_malloc(&inst, sizeof(u32));
  u32 row_bytes_ptr = w2c_decode__wasm_malloc(&inst, sizeof(u32));
#endif

  clock_gettime(CLOCK_REALTIME, &start);
#ifdef ENABLE_SIMD
  int status = w2c_decode__wasmsimd_png_decode(&inst, png_file, filelen, row_pointers_ptr, height_ptr, row_bytes_ptr);
#else
  int status = w2c_decode__wasm_png_decode(&inst, png_file, filelen, row_pointers_ptr, height_ptr, row_bytes_ptr);
#endif
  clock_gettime(CLOCK_REALTIME, &end);
  dt = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / BILLION;
  printf("time: %f\n", dt);
  fprintf(out, "%f\n", dt);
  fclose(out);

  u32 height = *(u32*) (&mem->data[height_ptr]);
  u32 row_bytes = *(u32*) (&mem->data[row_bytes_ptr]);
  u32 row_pointers = *(u32*) (&mem->data[row_pointers_ptr]);

  // Save the output to a file
  if (output_image_file && row_pointers && height > 0 && row_bytes > 0) {
    FILE *output_image = fopen(output_image_file, "wb");
    if (!fp) {
      printf("Invalid input image provided: %s. Not saving output.\n", output_image_file);
    } else {
      printf("Saving %u rows of %u bytes each to %s.\n", height, row_bytes, output_image_file);
      for(int y = 0; y < height; y++){
        u32 cur_ptr = *(u32*) &(mem->data[row_pointers]);
        fwrite(&(mem->data[cur_ptr]), sizeof(unsigned char), row_bytes, output_image);
        row_pointers += sizeof(u32);
      }
      fclose(output_image);
    }
  }


  /* Free the inst module. */
#ifdef ENABLE_SIMD
  wasm2c_decode__wasmsimd_free(&inst);
#else
  wasm2c_decode__wasm_free(&inst);
#endif
  free(buffer);
  uvwasi_destroy(&local_uvwasi_state);
  /* Free the Wasm runtime state. */
  wasm_rt_free();
  return 0;
}