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
//  ProresEncoder.m
//  prenc
//

#import "ProresEncoder.h"

#import <VideoToolbox/VTCompressionSession.h>
#import <pthread.h>


@interface ProresEncoder ()

@property (nonatomic)         VTCompressionSessionRef   compSess;

@property (nonatomic)         CFMutableArrayRef         encodedQueue;

@property (nonatomic)         int                       width;
@property (nonatomic)         int                       height;

@property (nonatomic)         CMTimeScale               tsNum;
@property (nonatomic)         CMTimeScale               tsDen;

@property (nonatomic)         uint64_t                  frameNumber;

@property (nonatomic)         pthread_mutex_t           *queueMutex;


@end


@implementation ProresEncoder

static void pixelBufferReleaseCb(void *releaseRefCon, const void *baseAddress)
{
    free(releaseRefCon);
}

static void frameEncodedCb(
                           void *outputCallbackRefCon,
                           void *sourceFrameRefCon,
                           OSStatus status,
                           VTEncodeInfoFlags infoFlags,
                           CMSampleBufferRef sampleBuffer)
{
    CMSampleBufferRef encodedSampleBuffer = NULL;
    ProresEncoder *encoder = (__bridge ProresEncoder *)outputCallbackRefCon;

    if (status != noErr || sampleBuffer == NULL)
        return;

    if (CMSampleBufferCreateCopy(kCFAllocatorDefault, sampleBuffer, &encodedSampleBuffer))
    {
        fprintf(stderr, "Cannot create encoded sample buffer.\n");
        return;
    }

    pthread_mutex_lock(encoder.queueMutex);
    {
        CFArrayAppendValue(encoder.encodedQueue, encodedSampleBuffer);
    }
    pthread_mutex_unlock(encoder.queueMutex);
}

- (id)init
{
    return [self initWithWidth:1920
                        height:1080
                         tsNum:1
                         tsDen:30
                        darNum:16
                        darDen:9
                     interlace:NO
           enableHwAccelerated:YES];
}

- (id)initWithWidth:(int)width
             height:(int)height
              tsNum:(uint32_t)tsNum
              tsDen:(uint32_t)tsDen
             darNum:(uint32_t)darNum
             darDen:(uint32_t)darDen
          interlace:(BOOL)interlace
enableHwAccelerated:(BOOL)enableHwAccelerated
{
    int ret = 0;
    CFMutableDictionaryRef encoderSpecification = NULL;

    if ((self = [super init]) == nil)
        return nil;

    self.frameNumber = 0;
    self.width = width;
    self.height = height;

    self.tsNum = tsNum;
    self.tsDen = tsDen;

    self.encodedQueue = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);

    _queueMutex = malloc(sizeof(pthread_mutex_t));
    if (pthread_mutex_init(_queueMutex, NULL))
    {
        fprintf(stderr, "Cannot create queue mutex.\n");
        return nil;
    }

    // create compression (encoding) session
    if (enableHwAccelerated)
    {
        encoderSpecification = CFDictionaryCreateMutable(
                                                         kCFAllocatorDefault,
                                                         1,
                                                         &kCFCopyStringDictionaryKeyCallBacks,
                                                         &kCFTypeDictionaryValueCallBacks);
        if (encoderSpecification)
            CFDictionarySetValue(
                                 encoderSpecification,
                                 kVTVideoEncoderSpecification_EnableHardwareAcceleratedVideoEncoder,
                                 kCFBooleanTrue);
        else
            fprintf(stderr, "Hardware acceleration property cannot be created.\n");
    }

    ret = VTCompressionSessionCreate(
                                     NULL,                               /* allocator                   */
                                     self.width,                         /* width                       */
                                     self.height,                        /* height                      */
                                     kCMVideoCodecType_AppleProRes422HQ, /* codecType                   */
                                     encoderSpecification,               /* encoderSpecification        */
                                     NULL,                               /* sourceImageBufferAttributes */
                                     NULL,                               /* compressedDataAllocator     */
                                     frameEncodedCb,                     /* outputCallback              */
                                     (__bridge void *)self,              /* outputCallbackRefCon        */
                                     &_compSess);                        /* compressionSessionOut       */
    if (ret)
    {
        fprintf(stderr, "ProRes encoder cannot be created. Internal error %d.\n", ret);
        return nil;
    }
    if (VTSessionSetProperty(_compSess, kVTCompressionPropertyKey_RealTime, kCFBooleanFalse))
        fprintf(stderr, "Encoder real-time mode cannot be disabled.\n");


    // set pixel aspect ratio
    ret = [self setPixelAspectRatioWithFrameWidth:self.width
                                      frameHeight:self.height
                                           darNum:darNum
                                           darDen:darDen];
    if (ret)
        fprintf(stderr, "Aspect ratio property (%d:%d) cannot be set (%d).\n", darNum, darDen, ret);

    // set interlace mode if necessary
    if (interlace)
    {
        ret = [self setInterlaceMode];
        if (ret)
            fprintf(stderr, "Cannot set interlace video property (%d).\n", ret);
    }

    return self;
}

- (BOOL)encodeWithRawImage:(uint8_t *)rawimg
{
    int ret = 0;
    CVPixelBufferRef pixBuf = NULL;
    CMTime pts = CMTimeMake(self.frameNumber * self.tsNum, self.tsDen);

    ret = CVPixelBufferCreateWithBytes(
                                       NULL,
                                       self.width,
                                       self.height,
                                       kCVPixelFormatType_422YpCbCr16,
                                       rawimg,
                                       self.width * 4,
                                       pixelBufferReleaseCb,
                                       rawimg,
                                       NULL,
                                       &pixBuf);
    if (ret)
        goto done;

    ret = VTCompressionSessionEncodeFrame(_compSess, pixBuf, pts, kCMTimeInvalid, NULL, NULL, NULL);
    if (ret)
        goto done;

    self.frameNumber++;

done:
    if (pixBuf)
        CFRelease(pixBuf);

    return (BOOL)!ret;
}

- (BOOL)hasEncodedFrame
{
    BOOL ret;
    pthread_mutex_lock(self.queueMutex);
    {
        ret = CFArrayGetCount(self.encodedQueue) > 0;
    }
    pthread_mutex_unlock(self.queueMutex);

    return ret;
}

- (CMSampleBufferRef)nextEncodedFrame
{
    if ([self hasEncodedFrame])
    {
        CMSampleBufferRef sampleBuffer;

        pthread_mutex_lock(self.queueMutex);
        {
            sampleBuffer = (CMSampleBufferRef)CFArrayGetValueAtIndex(self.encodedQueue, 0);
            CFArrayRemoveValueAtIndex(self.encodedQueue, 0);
        }
        pthread_mutex_unlock(self.queueMutex);

        return sampleBuffer;
    }
    else
        return NULL;
}

- (BOOL)flushFrames
{
    return (BOOL)!VTCompressionSessionCompleteFrames(_compSess, kCMTimeIndefinite);
}

- (void)dealloc
{
    if (_compSess)
    {
        VTCompressionSessionInvalidate(_compSess);
        CFRelease(_compSess);
    }

    if (_queueMutex)
    {
        pthread_mutex_destroy(_queueMutex);
        free(_queueMutex);
    }

    if (_encodedQueue)
    {
        CMSampleBufferRef buf;
        while ((buf = [self nextEncodedFrame]))
            CFRelease(buf);

        CFRelease(_encodedQueue);
    }

}

- (OSStatus)setPixelAspectRatioWithFrameWidth:(int)frameWidth
                                  frameHeight:(int)frameHeight
                                       darNum:(int)darNum
                                       darDen:(int)darDen
{
    OSStatus ret = noErr;
    int numValue = darNum * frameHeight;
    int denValue = darDen * frameWidth;

    if (darNum <= 0 || darDen <= 0)
        return ret;

    if (numValue % denValue == 0 && numValue / denValue == 1)
        return ret;

    CFNumberRef parNum = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &numValue);
    CFNumberRef parDen = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &denValue);


    CFMutableDictionaryRef par = CFDictionaryCreateMutable(
                                                           kCFAllocatorDefault,
                                                           2,
                                                           &kCFCopyStringDictionaryKeyCallBacks,
                                                           &kCFTypeDictionaryValueCallBacks);
    if (parNum == NULL || parDen == NULL || par == NULL)
    {
        ret = -1;
        goto done;
    }

    CFDictionarySetValue(
                         par,
                         kCMFormatDescriptionKey_PixelAspectRatioHorizontalSpacing,
                         parNum);

    CFDictionarySetValue(
                         par,
                         kCMFormatDescriptionKey_PixelAspectRatioVerticalSpacing,
                         parDen);

    ret = VTSessionSetProperty(
                               _compSess,
                               kVTCompressionPropertyKey_PixelAspectRatio,
                               par);

done:
    if (parNum)
        CFRelease(parNum);
    if (parDen)
        CFRelease(parDen);
    if (par)
        CFRelease(par);

    return ret;
}

- (OSStatus)setInterlaceMode
{
    OSStatus ret;
    int fieldValue = 2;
    CFNumberRef fieldCount = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &fieldValue);

    if (fieldCount == NULL)
    {
        ret = -1;
        goto done;
    }

    ret = VTSessionSetProperty(
                               _compSess,
                               kVTCompressionPropertyKey_FieldCount,
                               fieldCount);
    if (ret)
        goto done;

    ret = VTSessionSetProperty(
                               _compSess,
                               kVTCompressionPropertyKey_FieldDetail,
                               kCMFormatDescriptionFieldDetail_TemporalTopFirst);

done:
    if (fieldCount)
        CFRelease(fieldCount);

    return ret;
}

@end
