#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <png.h>
#include <simd128.h>
#include <time.h>

#define BILLION 1000000000.0
#define __USE_POSIX199309

unsigned int width, height;
png_bytep *row_pointers;
struct timespec start, end;
double dt;

static void process(void) {
	for (unsigned int y = 0; y < height; y++) {
		png_bytep row = row_pointers[y];
		for (unsigned int x = 0; x < width; x++) {
			png_bytep px = &(row[x * 4]);
			png_byte old[4 * sizeof(png_byte)];
			memcpy(old, px, sizeof(old));
			px[0] = 255 - old[0];
			px[1] = 255 - old[1];
			px[2] = 255 - old[2];
		}
	}
}

static void encode(char *filename) {
	FILE *fp = fopen(filename, "wb");
	png_structp png = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
	png_infop info = png_create_info_struct(png);
	png_init_io(png, fp);
	png_set_IHDR(png, info, width, height, 8, PNG_COLOR_TYPE_RGBA, 
		PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_DEFAULT, PNG_FILTER_TYPE_DEFAULT);
	png_write_image(png, row_pointers);
	png_write_end(png, info);
	fclose(fp);
}

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

	FILE *out = fopen(argv[2], "a");
	if (!out) {
		printf("Invalid file provided.\n");
		exit(1);
	}

	char *encoded;
	if (argc > 3) {
		encoded = argv[3];
	}

	png_structp png = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
	png_infop info = png_create_info_struct(png);
	png_init_io(png, fp);
	png_read_info(png, info);

	width = png_get_image_width(png, info);
	height = png_get_image_height(png, info);
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

	row_pointers = (png_bytep*)malloc(sizeof(png_bytep) * height);
	for (int y = 0; y < height; y++) {
			row_pointers[y] = (png_byte*)malloc(png_get_rowbytes(png,info));
	}

	if (encoded != NULL) {
		clock_gettime(CLOCK_REALTIME, &start);
		png_read_image(png, row_pointers);
		process();
		encode(encoded);
		clock_gettime(CLOCK_REALTIME, &end);
	} else {
		clock_gettime(CLOCK_REALTIME, &start);
		png_read_image(png, row_pointers);
		clock_gettime(CLOCK_REALTIME, &end);
	}

	dt = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / BILLION;
	fprintf(out, "%f\n", dt);
    
	fclose(fp);
	for(int y = 0; y < height; y++) {
		free(row_pointers[y]);
	}
	free(row_pointers);
}