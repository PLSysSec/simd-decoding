#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <png.h>
#include <time.h>

#define BILLION 1000000000.0
#define __USE_POSIX199309

int main(int argc, char *argv[]) {
	struct timespec start, end;
	double dt;

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

	png_structp png = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
	png_infop info = png_create_info_struct(png);
	png_init_io(png, fp);
	png_read_info(png, info);

	int width = png_get_image_width(png, info);
	int height = png_get_image_height(png, info);
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
	fprintf(out, "%f\n", dt);
    
	fclose(fp);
	for(int y = 0; y < height; y++) {
		free(row_pointers[y]);
	}
	free(row_pointers);
}
