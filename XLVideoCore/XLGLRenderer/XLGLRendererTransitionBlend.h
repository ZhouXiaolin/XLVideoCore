//
//  XLGLRendererTransitionBlend.h
//  XLVideoCore
//
//  Created by 周晓林 on 2018/6/1.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#import "XLGLRendererBase.h"
extern const char* kXLCompositorBlendFragmentShader;
@interface XLGLRendererTransitionBlend : XLGLRendererBase
- (void)renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer usingForegroundSourceBuffer:(CVPixelBufferRef)foregroundPixelBuffer andBackgroundSourceBuffer:(CVPixelBufferRef)backgroundPixelBuffer forTweenFactor:(float)tween type:(unsigned int) type;
@end
