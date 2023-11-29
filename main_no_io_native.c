#include <stdio.h>
#include <time.h>

#include "decode_no_io.h"

#define BILLION 1000000000.0


/**
 * argv[1]: png image filename to decode
 * argv[2]: output csv file for timing information
 * argv[3]: png output file
 */
int main(int argc, char *argv[]) {
  const char* input_file = NULL;
  const char* output_time_file = NULL;
  const char* output_image_file = NULL;

  if (argc < 3) {
    printf("Not enough arguments provided.\n");
    printf("Usage: ./%s <image> <output_time> <(optional) output_image> \n", argv[0]);
    exit(1);
  }

  input_file = argv[1];
  output_time_file = argv[2];

  if (argc > 3) {
    output_image_file = argv[3];
  }

  FILE *fp = fopen(input_file, "rb");
  if (!fp) {
    printf("Invalid input image provided: %s.\n", input_file);
    exit(1);
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
    exit(1);
  }

  struct timespec start, end;
  double dt = 1.0;

  unsigned char** row_pointers = NULL;
  size_t height = 0;
  size_t row_bytes = 0;

  clock_gettime(CLOCK_REALTIME, &start);
  int status = png_decode(buffer, filelen, &row_pointers, &height, &row_bytes);
  clock_gettime(CLOCK_REALTIME, &end);
  dt = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / BILLION;
  printf("time: %f\n", dt);
  fprintf(out, "%f\n", dt);
  fclose(out);

  // Save the output to a file
  if (output_image_file && row_pointers && height > 0 && row_bytes > 0) {
    FILE *output_image = fopen(output_image_file, "wb");
    if (!fp) {
      printf("Invalid input image provided: %s. Not saving output.\n", output_image_file);
    } else {
      printf("Saving %zu rows of %zu bytes each to %s.\n", height, row_bytes, output_image_file);
      for(int y = 0; y < height; y++){
        fwrite(row_pointers[y], sizeof(unsigned char), row_bytes, output_image);
      }
      fclose(output_image);
    }
  }

  // Row pointers contains our result
  if (row_pointers && height > 0) {
    for(int y = 0; y < height; y++) {
      free(row_pointers[y]);
    }
    free(row_pointers);
  }

  free(buffer);
  return 0;
}
