#include <stdio.h>
#include <time.h>

#include "decode_no_io.h"

#define BILLION 1000000000.0


/**
 * argv[1]: png image filename to decode
 * argv[2]: output csv file for timing information
 */
int main(int argc, char *argv[]) {
	if (argc < 3) {
		printf("Not enough arguments provided.\n");
		printf("Usage: ./%s <image> <output_time> \n", argv[0]);
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

    unsigned char *buffer = (unsigned char *)malloc(filelen * sizeof(unsigned char)); // Enough memory for the file
    fread(buffer, filelen, 1, fp); // Read in the entire file
    fclose(fp);

	
	FILE *out = fopen(argv[2], "a");
	if (!out) {
		printf("Invalid output file provided.\n");
		exit(1);
	}

    struct timespec start, end;
	double dt = 1.0;

    clock_gettime(CLOCK_REALTIME, &start);
	int status = png_decode(buffer, filelen);
    clock_gettime(CLOCK_REALTIME, &end);

    dt = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / BILLION;


	fprintf(out, "%f\n", dt);
    fclose(out);
	printf("time: %f\n", dt);
	return 0;
}
