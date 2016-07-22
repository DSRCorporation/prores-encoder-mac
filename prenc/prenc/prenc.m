// Copyright (C) 2016 Netflix, Inc.
//
//     This file is part of OS X ProRes encoder.
//
//     OS X ProRes encoder is free software: you can redistribute it and/or modify
//     it under the terms of the GNU General Public License as published by
//     the Free Software Foundation, either version 3 of the License, or
//     (at your option) any later version.
//
//     OS X ProRes encoder is distributed in the hope that it will be useful,
//     but WITHOUT ANY WARRANTY; without even the implied warranty of
//     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//     GNU General Public License for more details.
//
//     You should have received a copy of the GNU General Public License
//     along with OS X ProRes encoder.  If not, see <http://www.gnu.org/licenses/>.
//
//  prenc.m
//  prenc
//

#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <getopt.h>
#include <libgen.h>

#import "ProresEncoder.h"
#import "MovieWriter.h"


#define FORMAT_SCALE_STR     "scale="
#define FORMAT_DAR_STR       "setdar="
#define FORMAT_FPS_STR       "fps="
#define FORMAT_INTERLACE_STR "interlace"

/**
 * Prints usage of application.
 *
 * @param programName program name
 */
static void printUsage(char *programName)
{
    char *name = basename(programName);

    printf("Usage: %s [OPTION]... FILE\n", name);
    printf("Encode YUV 4:2:2 16-bit planar source from file\n"
           "or standard input to QuickTime Movie FILE using ProRes 422 HQ codec.\n");
    printf("Example: %s -i test.yuv -f scale=720:480,setdar=4/3,fps=30000/1001,interlace test.mov\n", name);
    printf("\n");
    printf("Options:\n");
    printf("  -i, --input=YUV_FILE    ""Input file with valid planar YUV 4:2:2 16-bit content.\n");
    printf("  -f, --format=FORMAT     ""Specific conversion video format settings, comma as delimeter.\n");
    printf("                            default scale=1920:1080,fps=30/1\n");
    printf("  -h, --help              ""Print this help.\n");
    printf("\n");
    printf("Format settings:\n");
    printf("  scale=WIDTH:HEIGHT      ""Sets frame size, default 1920x1080.\n");
    printf("  setdar=NUM:DEN          ""Sets display aspect ratio, default set by encoder.\n");
    printf("  fps=NUM:DEN             ""Sets video frame rate, default 30fps\n");
    printf("  interlace               ""Sets interlaced video, default progressive.\n");
}

/**
 * Parses format string and gets two parameters.
 *
 * @param formatStr format string
 * @param pattern pattern string to find
 * @param delimiter parameters delimiter
 * @param firstPar first parameter to set
 * @param secondPar second parameter to set
 */
static void getTwoParameters(const char *formatStr, const char *pattern, char delimiter, int *firstPar, int *secondPar)
{
    int  f = 0;
    int  s = 0;
    char tmp[256] = { 0 };
    char *delim;
    char *comma;
    long fs;
    long ss;
    char *format = strstr(formatStr, pattern);

    if (format == NULL)
        return;

    format += strlen(pattern);
    delim = strchr(format, delimiter);
    fs    = delim - format;

    if (delim == NULL || fs == 0 || fs > 255)
        return;

    memcpy(tmp, format, fs);
    f = atoi(tmp);
    if (f <= 0)
        return;

    format += fs + 1;
    comma = strchr(format, ',');
    ss = (comma) ? comma - format : strlen(format);
    if (ss == 0 || ss > 255)
        return;

    memset(tmp, 0, sizeof(tmp));
    memcpy(tmp, format, ss);
    s = atoi(tmp);
    if (s == 0)
        return;

    *firstPar  = f;
    *secondPar = s;
}

/**
 * Gets interlace parameter.
 *
 * @param formatStr format string
 * @param interlace interlace parameter to set
 */
static void getInterlacing(const char *formatStr, BOOL *interlace)
{
    if (strstr(formatStr, FORMAT_INTERLACE_STR))
        *interlace = YES;
}

/**
 * Parses format option value.
 *
 * @param formatStr format option value
 * @param width frame width to set
 * @param height frame height to set
 * @param tsNum timescale numerator to set
 * @param tsDen timescale denumerator to set
 * @param darNum display aspect ratio numerator to set
 * @param darDen display aspect ratio denumerator to set
 * @param interlace interlace flag to set
 */
static void parseFormat(const char *formatStr,
                        int *width,
                        int *height,
                        int *tsNum,
                        int *tsDen,
                        int *darNum,
                        int *darDen,
                        BOOL *interlace)
{
    getTwoParameters(formatStr, FORMAT_SCALE_STR, ':', width, height);
    getTwoParameters(formatStr, FORMAT_FPS_STR, '/', tsDen, tsNum);
    getTwoParameters(formatStr, FORMAT_DAR_STR, '/', darNum, darDen);
    getInterlacing(formatStr, interlace);
}

/**
 * Reads raw image data from input file.
 *
 * @param in intput file or stdin
 * @param rawimg raw image data pointer
 * @param rawimgSize raw image data size to read
 *
 * @return 0 on success, -1 on end of file and -2 on file errors
 */
static int readRawimage(FILE *in, uint8_t *rawimg, uint64_t rawimgSize)
{
    uint8_t *p = rawimg;
    uint64_t size = rawimgSize;
    size_t readNumber = 0;

    if (feof(in))
        return -1;

    do
    {
        readNumber = fread(p, 1, size, in);
        if (ferror(in))
            return -2;

        p += readNumber;
        size -= readNumber;
    }
    while (feof(in) == 0 && size);

    return 0;
}

/**
 * Converts planar YUV 4:2:2 16-bit to packed format.
 *
 * @param planar planar data pointer
 * @param width frame width
 * @param height frame height
 * @param packed converted output data pointer
 */
static void pack422YpCbCr16PlanarTo422YpCbCr16(uint8_t *planar, int width, int height, uint8_t *packed)
{
    int rowSize = width * 2;
    uint16_t *Y  = (uint16_t *)planar;
    uint16_t *Cb = (uint16_t *)(planar + height * width * 2);
    uint16_t *Cr = (uint16_t *)(planar + height * width * 3);
    uint16_t *p = (uint16_t *)packed;

    for (int r = 0; r < height; r++)
    {
        for (int cn = 0; cn < rowSize; cn += 4)
        {
            *p++ = *Cb++; // Cb0
            *p++ = *Y++;  // Y0
            *p++ = *Cr++; // Cr0
            *p++ = *Y++;  // Y1
        }

    }
}

/**
 * Writes frames from encoder internal queue to file.
 *
 * @param encoder ProresEncoder instance
 * @param writer MovieWriter instance
 */
static void writeEncodedFrames(ProresEncoder *encoder, MovieWriter *writer)
{
    CMSampleBufferRef sampleBuffer = NULL;

    while ((sampleBuffer = [encoder nextEncodedFrame]))
    {
        if (![writer writeSampleBuffer:sampleBuffer])
        {
            fprintf(stderr, "Cannot write encoded frame (%p).\n", sampleBuffer);
            continue;
        }

        CFRelease(sampleBuffer);
    }
}

int main(int argc, char *argv[])
{
    FILE          *in  = stdin;
    char          *outFileName = NULL;
    uint8_t       *rawimg = { 0 };
    size_t        rawimgSize = 0;
    int           width = 1920;
    int           height = 1080;
    int           tsNum = 1;
    int           tsDen = 30;
    int           darNum = 0;
    int           darDen = 0;
    BOOL          interlace = NO;
    BOOL          hwAccel = YES;
    int           opt;
    int           ret;
    ProresEncoder *encoder;
    MovieWriter   *movieWriter;
    static struct option longopts[] = {
        { "input" , required_argument, NULL, 'i' },
        { "format", required_argument, NULL, 'f' },
        { "help"  , no_argument      , NULL, 'h' },
        { NULL    , 0                , NULL, 0 }
    };


    while ((opt = getopt_long(argc, argv, "i:f:h", longopts, NULL)) != -1)
    {
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

            case 'f':
                parseFormat(optarg, &width, &height, &tsNum, &tsDen, &darNum, &darDen, &interlace);
                if (darNum)
                    printf("Video settings: %dx%d %d/%d %d/%d %s\n",
                        width, height, tsDen, tsNum, darNum, darDen, (interlace) ? "interlaced" : "progressive");
                else
                    printf("Video settings: %dx%d %d/%d %s\n",
                        width, height, tsDen, tsNum, (interlace) ? "interlaced" : "progressive");
            break;

            case 'h':
                printUsage(argv[0]);
                return EXIT_SUCCESS;
            break;

            default:
                /* do nothing */ ;
        }
    }

    if (argc <= optind)
    {
        fprintf(stderr, "Ecpected output file name argument after options.\n");
        return EXIT_FAILURE;
    }

    outFileName = argv[optind];

    movieWriter = [[MovieWriter alloc] initWithOutFile:[NSString stringWithUTF8String:outFileName]];
    if (movieWriter == nil)
        return EXIT_FAILURE;

    encoder = [[ProresEncoder alloc] initWithWidth:width
                                            height:height
                                             tsNum:tsNum
                                             tsDen:tsDen
                                            darNum:darNum
                                            darDen:darDen
                                         interlace:interlace
                               enableHwAccelerated:hwAccel];
    if (encoder == nil)
        return EXIT_FAILURE;

    rawimgSize = height * width * 4; // 4:2:2 16bit -> (width * 2 + width + width) * height
    rawimg = malloc(rawimgSize);
    if (rawimg == NULL)
    {
        fprintf(stderr, "Memory for input data cannot be allocated.\n");
        return EXIT_FAILURE;
    }

    printf("Encoding started to file %s\n", outFileName);

    while ((ret = readRawimage(in, rawimg, rawimgSize)) == 0)
    {
        // packedYUV should not be released manually and will be managed by encoder
        uint8_t *packedYUV = malloc(rawimgSize);
        if (packedYUV == NULL)
        {
            fprintf(stderr, "Memory for packed image cannot be allocated.\n");
            return EXIT_FAILURE;
        }

        memset(packedYUV, 0, rawimgSize);

        pack422YpCbCr16PlanarTo422YpCbCr16(rawimg, width, height, packedYUV);

        if (![encoder encodeWithRawImage:packedYUV])
        {
            fprintf(stderr, "Cannot encode raw image. Skip this portion of data (%p).\n", packedYUV);
            continue;
        }

        writeEncodedFrames(encoder, movieWriter);
    }

    // flush all encoded frames from internal queue
    if (![encoder flushFrames])
        fprintf(stderr, "Cannot flush encoded frames.\n");

    // write all frames after flush encoder
    writeEncodedFrames(encoder, movieWriter);

    // write movie file format metadata
    [movieWriter finishWriting];

    printf("Encoding finished.\n");

    free(rawimg);
    fclose(in);

    return (ret <= -2) ? EXIT_FAILURE : EXIT_SUCCESS;
}
