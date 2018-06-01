//
//  XLGLMaskTransitionRenderer.h
//  XLVideoCore
//
//  Created by 周晓林 on 2018/5/31.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XLGLRendererBase.h"
// 转场渲染  mask方式
extern NSString*  const  kRDCompositorPassThroughMaskFragmentShader;
@interface XLGLRendererTransitionMask : XLGLRendererBase
- (void) renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer
usingForegroundSourceBuffer:(CVPixelBufferRef)foregroundPixelBuffer
 andBackgroundSourceBuffer:(CVPixelBufferRef)backgroundPixelBuffer
          andMaskImagePath:(NSURL *) path
            forTweenFactor:(float)tween;
@end
