//
//  XLGLSimpleTransitionRenderer.h
//  XLVideoCore
//
//  Created by 周晓林 on 2018/5/31.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XLGLRendererBase.h"
// 转场渲染 简单类型

@interface XLGLRendererTransitionSimple : XLGLRendererBase
- (void)  renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer
usingForegroundSourceBuffer:(CVPixelBufferRef)foregroundPixelBuffer
  andBackgroundSourceBuffer:(CVPixelBufferRef)backgroundPixelBuffer
             forTweenFactor:(float)tween
                       type:(unsigned int) type;
@end
