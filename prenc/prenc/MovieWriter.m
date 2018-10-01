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
//  MovieWriter.m
//  prenc
//

#import "MovieWriter.h"

#import <AVFoundation/AVFoundation.h>


@interface MovieWriter ()

@property (strong, nonatomic) AVAssetWriter      *assetWriter;
@property (strong, nonatomic) AVAssetWriterInput *assetInput;
@property (assign, nonatomic) CMTimeScale timescale;

@end


@implementation MovieWriter

- (id)init
{
    return [self initWithOutFile:@"output.mov" timescale:600];
}

- (id)initWithOutFile:(NSString *)outFileName timescale:(CMTimeScale)ts
{
    NSURL   *url = nil;
    NSError *error;

    if ((self = [super init]) == nil)
        return nil;
    
    self.timescale = ts;
    
    url = [[NSURL alloc] initFileURLWithPath:outFileName];
    // remove if file already exists
    if (![[NSFileManager defaultManager] removeItemAtPath:[url path] error:&error])
    {
        if (error.code != NSFileNoSuchFileError)
        {
            fprintf(stderr, "Output file already exist and cannot be removed(%ld).\n", (long)error.code);
            return nil;
        }
    }

    self.assetInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:nil];
    if (self.assetInput == nil)
    {
        fprintf(stderr, "Cannot create asset input.\n");
        return nil;
    }

    self.assetWriter = [AVAssetWriter assetWriterWithURL:url fileType:AVFileTypeQuickTimeMovie error:&error];
    if (self.assetWriter == nil)
    {
        fprintf(stderr, "Cannot create asset writer.\n");
        return nil;
    }

    self.assetWriter.movieTimeScale = self.timescale;
    self.assetInput.mediaTimeScale = self.timescale;
    
    [self.assetWriter addInput:self.assetInput];

    if (![self.assetWriter startWriting])
    {
        fprintf(stderr, "Cannot start writing.\n");
        return nil;
    }

    [self.assetWriter startSessionAtSourceTime:kCMTimeZero];

    return self;
}

- (BOOL)writeSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (sampleBuffer == NULL)
        return NO;

    // wait until the writer is ready
    while (!self.assetInput.isReadyForMoreMediaData)
        usleep(1000);

    if (![self.assetInput appendSampleBuffer:sampleBuffer])
        return NO;

    return YES;
}

- (void)finishWriting
{
    while (!self.assetInput.isReadyForMoreMediaData)
        usleep(1000);

    [self.assetWriter finishWritingWithCompletionHandler:^{}];

    while (self.assetWriter.status    != AVAssetWriterStatusCompleted
           && self.assetWriter.status != AVAssetWriterStatusFailed
           && self.assetWriter.status != AVAssetWriterStatusCancelled)
        usleep(1000);
}

- (void)dealloc
{
    self.assetInput  = nil;
    self.assetWriter = nil;
}

@end
