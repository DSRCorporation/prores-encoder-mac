//
//  MovieWriter.h
//  prenc
//
//  Created by Grigoriy Gavrilov on 7/14/16.
//  Copyright © 2016 Grigoriy Gavrilov. All rights reserved.
//

#ifndef MovieWriter_h
#define MovieWriter_h

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@interface MovieWriter : NSObject

- (id)initWithOutFile:(NSString *)outFileName;

- (BOOL)writeSampleBuffer:(CMSampleBufferRef)sampleBuffer;

- (void)finishWriting;

@end

#endif /* MovieWriter_h */
