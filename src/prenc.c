#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>


#define BIT_PER_PIXEL 20


static int parse_size(const char *size_str, int *width, int *height)
{
    int  w = 0;
    int  h = 0;
    char tmp[256] = { 0 };
    char *x = strchr(size_str, 'x');
    int  ws = x - size_str;

    if (x == NULL || ws == 0 || ws > 255)
        return -1;

    memcpy(tmp, size_str, ws);
    w = atoi(tmp);

    h = atoi(x + 1);

    if (w == 0 || h == 0)
        return -1;

    *width  = w;
    *height = h;

    return 0;
}

static int read_rawimage(FILE *in, uint8_t *rawimg, uint64_t rawimg_size)
{
    uint8_t *p = rawimg;
    uint64_t size = rawimg_size;
    size_t read_number = 0;

    if (feof(in))
        return -1;

    do
    {
        read_number = fread(p, 1, size, in);
        if (ferror(in))
            return -2;

        p += read_number;
        size -= read_number;
    }
    while (feof(in) == 0 && size);

    return 0;
}

static int write_packet(FILE *out, uint8_t *rawimg, uint64_t rawimg_size)
{
    uint8_t *p = rawimg;
    uint64_t size = rawimg_size;
    size_t write_number = 0;

    while (size)
    {
        write_number = fwrite(p, 1, size, out);
        if (ferror(out))
            return -2;

        p += write_number;
        size -= write_number;
    }

    fflush(out);

    return 0;
}

static int encode(uint8_t *rawimg, uint64_t rawimg_size, uint8_t *pkt, uint64_t pkt_size)
{
    return 0;
}

int main(int argc, char *argv[])
{
    FILE *in  = stdin;
    FILE *out = stdout;    
    uint8_t *rawimg = NULL;
    uint64_t rawimg_size;
    uint64_t line_size;
    uint8_t *pkt = NULL;
    uint64_t pkt_size;
    int width = 1920;
    int height = 1080;
    int  opt;
    int  ret;

    while ((opt = getopt(argc, argv, "i:o:s:?h")) != -1) {
        switch (opt) 
        {
            case 'i':
                in = fopen(optarg, "r");
                if (in == NULL)
                {
                    perror("Input file opening fails");
                    return EXIT_FAILURE;
                }
            break;

            case 'o':
                out = fopen(optarg, "r");
                if (out == NULL)
                {
                    perror("Output file opening fails");
                    return EXIT_FAILURE;
                }
            break;

            case 's':
                if (parse_size(optarg, &width, &height))
                {
                    fprintf(stderr, "Size option value '%s' cannot be parsed.\n", optarg);
                    return EXIT_FAILURE;
                }
            break;

            case 'h':
            case '?':
                fprintf(stderr, "Usage: %s [-i infile] [-o outfile]\n", argv[0]);
                return EXIT_SUCCESS;
            break;

            default:
                /* do nothing */ ;
        }
    }

    line_size = width * BIT_PER_PIXEL / 8;
    rawimg_size = line_size * height;
    rawimg = malloc(rawimg_size);

    pkt_size = rawimg_size;
    pkt = rawimg;

    while ((ret = read_rawimage(in, rawimg, rawimg_size)) == 0)
    {   
        /* TODO: only for test and should be removed  */
        memset(rawimg + line_size * height / 2, 0x55, line_size * 4);

        if (encode(rawimg, rawimg_size, pkt, pkt_size))
        {
            fprintf(stderr, "Cannot encode raw image.\n");
            continue;
        }

        write_packet(out, pkt, pkt_size);
    }

    if (rawimg)
        free(rawimg);

    fclose(in);
    fclose(out);

    return (ret <= -2) ? EXIT_FAILURE : EXIT_SUCCESS;
}
