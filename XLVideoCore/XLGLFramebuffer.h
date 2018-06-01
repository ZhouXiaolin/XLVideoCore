//
//  XLGLFramebuffer.h
//  XLVideoCore
//
//  Created by 周晓林 on 2018/5/31.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
@interface XLGLFramebuffer : NSObject

- (void) render:(CVPixelBufferRef) destinationPixelBuffer;
@end
