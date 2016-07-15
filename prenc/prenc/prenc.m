#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>

#import "ProresEncoder.h"
#import "MovieWriter.h"


static int parse_size(const char *size_str, int *width, int *height)
{
    int  w = 0;
    int  h = 0;
    char tmp[256] = { 0 };
    char *x = strchr(size_str, 'x');
    long  ws = x - size_str;

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

#if 0
static int write_packet(FILE *out, uint8_t *rawimg, uint64_t rawimg_size)
{
    uint8_t *p = rawimg;
    uint64_t size = rawimg_size;
    size_t write_number = 0;

    if (rawimg == NULL || rawimg_size == 0)
        return 0;

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
#endif

static void pack(uint8_t *planar, uint8_t *packed)
{
    int componentsPerLine = 1920 * 2;
    for (int i = 0; i < componentsPerLine; i++)
    {
        
    }
}

int main(int argc, char *argv[])
{
    FILE                    *in  = stdin;
    char                    *outFileName = NULL;
    uint8_t                 *rawimg = { 0 };
    uint8_t                 *packedYUV = { 0 };
    size_t                  rawimgSize = 0;
    int                     width = 1920;
    int                     height = 1080;
    int                     opt;
    int                     ret;
    ProresEncoder *encoder;
    MovieWriter   *movieWriter;

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
                outFileName = strdup(optarg);
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
                fprintf(stderr, "Usage: %s [-i infile] outfile\n", argv[0]);
                return EXIT_SUCCESS;
            break;

            default:
                /* do nothing */ ;
        }
    }
    //in = fopen("/Users/ggavrilov/develop/netflix/media/marvel_animation_trailer_hd_woa_10s_yuv420p_1920x1080_30.raw", "r");
    //in = fopen("/Users/ggavrilov/develop/netflix/media/marvel_animation_trailer_hd_woa_10s_yuyv422_1920x1080_30.raw", "r");
    //in = fopen("/Users/ggavrilov/develop/netflix/media/marvel_animation_trailer_hd_woa_10s_yuv422p_1920x1080_30.raw", "r");
    //in = fopen("/Users/ggavrilov/develop/netflix/media/marvel_animation_trailer_hd_woa_10s_yuv422p10le_1920x1080_30.raw", "r");
    in = fopen("/Users/ggavrilov/develop/netflix/media/marvel_animation_trailer_hd_woa_10s_yuv422p16le_1920x1080_30.raw", "r");

    movieWriter = [[MovieWriter alloc] initWithOutFile:@"/Users/ggavrilov/develop/netflix/media/prenc_out.mov"];
    
    encoder = [[ProresEncoder alloc] initWithWidth:width
                                            height:height
                                         numerator:30
                                       denumerator:1];
    
    //rawimgSize = width * height * 4; // 422 10bit
    //rawimgSize = width * height + width * height / 2; // 420
    //rawimgSize = height * width * 2; // 422
    rawimgSize = height * width * 4; // 422 16bit
    rawimg = malloc(rawimgSize);
    if (rawimg == NULL)
    {
        NSLog(@"Memory for input data cannot be allocated.");
        return EXIT_FAILURE;
    }
    
    packedYUV = malloc(rawimgSize);
    
    printf("Encoding started to file %s\n", outFileName);
    
    while ((ret = read_rawimage(in, rawimg, rawimgSize)) == 0)
    {
        CMSampleBufferRef sampleBuf;
        
        pack(rawimg, packedYUV);

        if (![encoder encodeWithRawImage:packedYUV sampleBuffer:&sampleBuf])
        {
            NSLog(@"Cannot encode raw image. Skip this portion of data.");
            continue;
        }
        
        if (![movieWriter writeSampleBuffer:sampleBuf])
        {
            NSLog(@"Cannot write encoded data.");
            //continue;
            //return -1;
        }
        
        CFRelease(sampleBuf);
    }
    
    [movieWriter finishWriting];
    
    printf("Encoding finished.\n");
    
    free(rawimg);
    if (outFileName)
      free(outFileName);

    fclose(in);

    return (ret <= -2) ? EXIT_FAILURE : EXIT_SUCCESS;
}
