//
//  MovieWriter.m
//  prenc
//
//  Created by Grigoriy Gavrilov on 7/14/16.
//  Copyright © 2016 Grigoriy Gavrilov. All rights reserved.
//

#import "MovieWriter.h"

#import <AVFoundation/AVFoundation.h>


@interface MovieWriter ()

@property (strong, nonatomic) AVAssetWriter                        *assetWriter;
@property (strong, nonatomic) AVAssetWriterInput                   *assetInput;

@end


@implementation MovieWriter

- (id)init
{
    return [self initWithOutFile:@"output.mov"];
}

- (id)initWithOutFile:(NSString *)outFileName
{
    NSURL   *url = nil;
    NSError *error;
    
    if ((self = [super init]) == nil)
        return nil;
    
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