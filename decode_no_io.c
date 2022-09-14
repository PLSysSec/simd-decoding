#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <png.h>
#include <time.h>

#if defined __has_include
#  if __has_include ("simd128.h")
#    include "simd128.h"
#  endif
#endif

// Add line #include <simd128.h> to libpng/intel/filter_sse2_intrinsics.c

#define BILLION 1000000000.0
#define __USE_POSIX199309

struct png_file {
	unsigned char *buf;
	unsigned int size;
	unsigned int cur;
};

typedef struct png_file png_file;

void read_data_from_buffer(png_structp png, png_bytep out, png_size_t len) {
	png_voidp io_ptr = png_get_io_ptr(png);
	if (io_ptr == NULL) {
		return;
	}

	//fprintf(stderr, "Reading %ld bytes\n", len);

	png_file *f = (png_file*) io_ptr;
	memcpy(out, f->buf+f->cur, len);
	//out = f->buf+f->cur;

	// update the current pointer by the length we just read
	f->cur += len;
}


double timed_decode(unsigned char* png_fl, unsigned int size) {
	struct timespec start, end;
	double dt = 1.0;

	png_file f = {
		.buf = png_fl,
		.size = size,
		.cur = 0,
	};
	//fprintf(stderr, "Reading file of size %u\n", size);
	png_structp png = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
	png_infop info = png_create_info_struct(png);

	png_set_read_fn(png, &f, read_data_from_buffer);

	png_read_info(png, info);
	
	int width = png_get_image_width(png, info);
	//fprintf(stderr, "PNG Width %d \n", width);
	int height = png_get_image_height(png, info);
	//fprintf(stderr, "PNG Height %d \n", height);
	png_byte color_type = png_get_color_type(png, info);
	png_byte bit_depth = png_get_bit_depth(png, info);
	if (bit_depth == 16) png_set_strip_16(png);
	if (color_type == PNG_COLOR_TYPE_PALETTE) png_set_palette_to_rgb(png);
	/* PNG_COLOR_TYPE_GRAY_ALPHA is always 8 or 16bit depth. */
	if (color_type == PNG_COLOR_TYPE_GRAY && bit_depth < 8) png_set_expand_gray_1_2_4_to_8(png);
	if (png_get_valid(png, info, PNG_INFO_tRNS)) png_set_tRNS_to_alpha(png);
	/* These color_type don't have an alpha channel then fill it with 0xff. */
	if (color_type == PNG_COLOR_TYPE_RGB ||
					color_type == PNG_COLOR_TYPE_GRAY ||
					color_type == PNG_COLOR_TYPE_PALETTE) png_set_filler(png, 0xFF, PNG_FILLER_AFTER);
	else if (color_type == PNG_COLOR_TYPE_GRAY ||
					color_type == PNG_COLOR_TYPE_GRAY_ALPHA) png_set_gray_to_rgb(png);
	png_read_update_info(png, info);
	
	png_bytep *row_pointers = (png_bytep*)malloc(sizeof(png_bytep) * height);
	for (int y = 0; y < height; y++) {
			row_pointers[y] = (png_byte*)malloc(png_get_rowbytes(png,info));
	}
	
	clock_gettime(CLOCK_REALTIME, &start);
	png_read_image(png, row_pointers);
	clock_gettime(CLOCK_REALTIME, &end);
	dt = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / BILLION;

	for(int y = 0; y < height; y++) {
		free(row_pointers[y]);
	}
	free(row_pointers);

	return dt;
}

/**
 * argv[1]: png image filename to decode
 * argv[2]: output csv file for timing information
 */
int main(int argc, char *argv[]) {
	if (argc < 2) {
		printf("Not enough arguments provided.\n");
		exit(1);
	}

	FILE *fp = fopen(argv[1], "rb"); 
	if (!fp) {
		printf("Invalid file provided.\n");
		exit(1);
	}
    fseek(fp, 0, SEEK_END); 
    long filelen = ftell(fp);
    rewind(fp);

    unsigned char *buffer = (unsigned char *)malloc(filelen * sizeof(unsigned char)); // Enough memory for the file
    fread(buffer, filelen, 1, fp); // Read in the entire file
    fclose(fp);

	
	FILE *out = fopen(argv[2], "a");
	if (!out) {
		printf("Invalid file provided.\n");
		exit(1);
	}

	double dt = timed_decode(buffer, filelen);

	fprintf(out, "%f\n", dt);
    fclose(out);

	return 0;
}
