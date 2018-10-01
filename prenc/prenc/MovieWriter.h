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
//  MovieWriter.h
//  prenc
//

#ifndef MovieWriter_h
#define MovieWriter_h

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

/**
 * MovieWriter provides interface to create QuickTime Movie files.
 */
@interface MovieWriter : NSObject

/**
 * Initializes MovieWriter instance with output file name.
 *
 * @param outFileName output file name
 * @return instance of MovieWriter, nil otherwise
 */
- (id)initWithOutFile:(NSString *)outFileName timescale:(CMTimeScale)ts;

/**
 * Writes CMSampleBuffer with encoded data to QuickTime Movie file.
 *
 * @param sampleBuffer Core Media sample buffer with encoded data
 * @return YES on success writing, NO otherwise
 */
- (BOOL)writeSampleBuffer:(CMSampleBufferRef)sampleBuffer;

/**
 * Finishes data writing and closes output file.
 */
- (void)finishWriting;

@end

#endif /* MovieWriter_h */
