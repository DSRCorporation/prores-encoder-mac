//
//  ProresEncoder.m
//  prenc
//
//  Created by Grigoriy Gavrilov on 7/14/16.
//  Copyright © 2016 Grigoriy Gavrilov. All rights reserved.
//
#import "ProresEncoder.h"


#import <VideoToolbox/VTCompressionSession.h>

@interface ProresEncoder ()

@property (nonatomic)         VTCompressionSessionRef              compSess;
@property (nonatomic)         CMSampleBufferRef                    sampleBuffer;

@property (nonatomic)         int                                  width;
@property (nonatomic)         int                                  height;
@property (nonatomic)         int                                  lineSize;

@property (nonatomic)         CMTimeScale                          num;
@property (nonatomic)         CMTimeScale                          den;

@property (nonatomic)         uint64_t                             frameNumber;

@property                     BOOL                                 isEncodingFinished;
@property                     int                                  encodingError;

@end


@implementation ProresEncoder

static void frame_encoded_cb(void *outputCallbackRefCon,
                             void *sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sampleBuffer)
{
    ProresEncoder *encoder = (__bridge ProresEncoder *)outputCallbackRefCon;
    CMSampleBufferRef outSampleBuffer = NULL;
    int ret;
    
    encoder.encodingError = 0;
    
    if (sampleBuffer == NULL)
    {
        encoder.encodingError = 1;
        return;
    }
    
    if ((ret = CMSampleBufferCreateCopy(kCFAllocatorDefault, sampleBuffer, &outSampleBuffer)))
    {
        encoder.encodingError = 2;
        NSLog(@"Copy of sample buffer failed(%d).", ret);
        return;
    }
    
    encoder.sampleBuffer = outSampleBuffer;
    encoder.isEncodingFinished = YES;
}

- (id)init
{
    return [self initWithWidth:1920 height:1080 numerator:30 denumerator:1];
}

- (id)initWithWidth:(int)width
             height:(int)height
          numerator:(uint32_t)num
        denumerator:(uint32_t)den
{
    int ret = 0;
    
    if ((self = [super init]) == nil)
        return nil;
    
    self.frameNumber = 0;
    self.width = width;
    self.height = height;
    self.lineSize = self.width * BIT_PER_PIXEL / 8;
    
    self.num = num;
    self.den = den;
    
    self.sampleBuffer = NULL;
    
    // create compression (encoding) session
    ret = VTCompressionSessionCreate(
                                     NULL,                               /* allocator                   */
                                     self.width,                         /* width                       */
                                     self.height,                        /* height                      */
                                     kCMVideoCodecType_AppleProRes422HQ, /* codecType                   */
                                     NULL,                               /* encoderSpecification        */
                                     NULL,                               /* sourceImageBufferAttributes */
                                     NULL,                               /* compressedDataAllocator     */
                                     frame_encoded_cb,                   /* outputCallback              */
                                     (__bridge void *)self,              /* outputCallbackRefCon        */
                                     &_compSess);                        /* compressionSessionOut       */
    if (ret)
    {
        NSLog(@"ProRes encoder cannot be created. Internal error %d.", ret);
        return nil;
    }

    return self;
}

- (void)setSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    _sampleBuffer = sampleBuffer;
}

- (BOOL)encodeWithRawImage:(uint8_t *)rawimg sampleBuffer:(CMSampleBufferRef *)sampleBuffer
{
    int ret = 0;
    CVPixelBufferRef pixBuf = NULL;
    CMTime pts = CMTimeMake(self.frameNumber * self.den, self.num);
#if 0
    //uint64_t rawimgSize = self.width * self.height * 4;
    size_t planeWidth[]        = { self.width, self.width / 2, self.width / 2 };
    size_t planeHeight[]       = { self.height, self.height, self.height };
    size_t planeBytesPerRow[]  = { self.width, self.width, self.width };
    void   *planeBaseAddress[] = { rawimg, rawimg + self.height * self.width, rawimg + self.height * (self.width + self.width / 2) };
#else
    size_t planeWidth[]        = { self.width, self.width / 2, self.width / 2 };
    size_t planeHeight[]       = { self.height, self.height / 2, self.height / 2 };
    size_t planeBytesPerRow[]  = { self.width, self.width / 2, self.width / 2 };
    void   *planeBaseAddress[] = { rawimg, rawimg + self.height * self.width, rawimg + self.height * (self.width + self.width / 4) };
#endif
    CVPlanarPixelBufferInfo_YCbCrPlanar *descriptor = malloc(sizeof(CVPlanarPixelBufferInfo_YCbCrPlanar));
    memset(descriptor, 0, sizeof(CVPlanarPixelBufferInfo_YCbCrPlanar));
    
#if 1
    self.lineSize = self.width * 4;
    ret = CVPixelBufferCreateWithBytes(
                                       NULL,
                                       self.width,
                                       self.height,
                                       kCVPixelFormatType_422YpCbCr16,
                                       rawimg,
                                       self.lineSize,
                                       NULL,
                                       NULL,
                                       NULL,
                                       &pixBuf);
#else
    ret = CVPixelBufferCreateWithPlanarBytes(
                                             NULL,
                                             self.width,
                                             self.height,
                                             //kCVPixelFormatType_422YpCbCr10,
                                             //kCVPixelFormatType_420YpCbCr8Planar,
                                             kCVPixelFormatType_422YpCbCr8,
                                             &descriptor,
                                             //rawimgSize,
                                             0,
                                             3,
                                             planeBaseAddress,
                                             planeWidth,
                                             planeHeight,
                                             planeBytesPerRow,
                                             NULL,
                                             NULL,
                                             NULL,
                                             &pixBuf);
#endif
    if (ret)
        goto done;
    
    ret = VTCompressionSessionEncodeFrame(_compSess, pixBuf, pts, kCMTimeInvalid, NULL, NULL, NULL);
    if (ret)
        goto done;
    
    while (!self.isEncodingFinished && self.encodingError == 0)
        usleep(1000);
    
    self.isEncodingFinished = NO;
    
    if (self.encodingError)
    {
        ret = self.encodingError;
        goto done;
    }
    
    self.frameNumber++;
    *sampleBuffer = self.sampleBuffer;
    
done:
    if (descriptor)
        free(descriptor);
    if (pixBuf)
        CFRelease(pixBuf);
    
    return (BOOL)!ret;
}

- (void)dealloc
{
    VTCompressionSessionInvalidate(_compSess);
    CFRelease(_compSess);
}

@end