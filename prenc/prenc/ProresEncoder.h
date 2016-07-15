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


//#define BIT_PER_PIXEL 20
#define BIT_PER_PIXEL 32


@interface ProresEncoder : NSObject

- (id)initWithWidth:(int)width
             height:(int)height
          numerator:(uint32_t)num
        denumerator:(uint32_t)den;

- (BOOL)encodeWithRawImage:(uint8_t *)rawimg sampleBuffer:(CMSampleBufferRef *)sampleBuffer;
@end


#endif /* ProresEncoder_h */
