//
//  XLVideoCompositorRenderer.h
//  XLVideoCore
//
//  Created by 周晓林 on 2018/5/28.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "XLScene.h"
#import "XLVideoCompositorInstruction.h"
@interface XLVideoCompositorRenderer : NSObject


@property (nonatomic,assign) CGSize videoSize;
+ (XLVideoCompositorRenderer *) sharedVideoCompositorRender;
- (void) clear;

- (void) particleRenderPixeBuffer:(CVPixelBufferRef) destinationPixelBuffer
                 usingSouceBuffer:(CVPixelBufferRef) sourcePixelBuffer;
- (void) renderCustomPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer
                           scene:(XLScene *)scene
                         request:(AVAsynchronousVideoCompositionRequest *)request; //渲染核心函数

- (void)  renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer
usingForegroundSourceBuffer:(CVPixelBufferRef)foregroundPixelBuffer
  andBackgroundSourceBuffer:(CVPixelBufferRef)backgroundPixelBuffer
             forTweenFactor:(float)tween
                       type:(unsigned int) type;

- (void) renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer
usingForegroundSourceBuffer:(CVPixelBufferRef)foregroundPixelBuffer
 andBackgroundSourceBuffer:(CVPixelBufferRef)backgroundPixelBuffer
          andMaskImagePath:(NSURL *) path
            forTweenFactor:(float)tween;
@end

