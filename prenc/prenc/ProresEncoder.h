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
//  ProresEncoder.h
//  prenc
//

#ifndef ProresEncoder_h
#define ProresEncoder_h

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <VideoToolbox/VTCompressionSession.h>


/**
 * ProresEncoder provides access to VideoToolbox ProRes encoder.
 */
@interface ProresEncoder : NSObject

/**
 * Initializes encoder with video settings.
 *
 * @param width frame width
 * @param height frame height
 * @param tsNum timescale numerator (1001/30000)
 * @param tsDen timescale denumerator (1001/30000)
 * @param darNum display aspect ratio numerator
 * @param darDen display aspect ratio denumerator
 * @param interlace interlaced video or not
 * @param enableHwAccelerated enable HW accelerated
 *
 * @return initialized ProresEncoder instance, nil otherwise
 */
- (id)initWithWidth:(int)width
             height:(int)height
              tsNum:(uint32_t)tsNum
              tsDen:(uint32_t)tsDen
             darNum:(uint32_t)darNum
             darDen:(uint32_t)darDen
          interlace:(BOOL)interlace
enableHwAccelerated:(BOOL)enableHwAccelerated;

/**
 * Encodes YUV 4:2:2 16-bit image data and puts result to internal buffer.
 *
 * @param rawimg YUV 4:2:2 16-bit image data pointer
 * @return YES on success encoding, NO otherwise
 */
- (BOOL)encodeWithRawImage:(uint8_t *)rawimg;

/**
 * Gets encoded frame from internal queue.
 *
 * @return Core Media sample buffer with encoded data if exists or nil if no frames
 */
- (CMSampleBufferRef)nextEncodedFrame;

/**
 * Flushes encoder data.
 *
 * return YES on success, NO otherwise
 */
- (BOOL)flushFrames;

@end


#endif /* ProresEncoder_h */
