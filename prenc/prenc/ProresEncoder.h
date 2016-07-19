//
//  ProresEncoder.h
//  prenc
//
//  Created by Grigoriy Gavrilov on 7/14/16.
//  Copyright © 2016 Grigoriy Gavrilov. All rights reserved.
//

#ifndef ProresEncoder_h
#define ProresEncoder_h

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <VideoToolbox/VTCompressionSession.h>


@interface ProresEncoder : NSObject

- (id)initWithWidth:(int)width
             height:(int)height
              tsNum:(uint32_t)tsNum
              tsDen:(uint32_t)tsDen
             darNum:(uint32_t)darNum
             darDen:(uint32_t)darDen
          interlace:(BOOL)interlace
enableHwAccelerated:(BOOL)enableHwAccelerated;

- (BOOL)encodeWithRawImage:(uint8_t *)rawimg;

- (CMSampleBufferRef)nextEncodedFrame;

- (BOOL)flushFrames;

@end


#endif /* ProresEncoder_h */
