//
//  XLGLParticleRenderer.h
//  XLVideoCore
//
//  Created by 周晓林 on 2018/5/31.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XLGLRendererBase.h"
// 粒子渲染 
@interface XLGLRendererParticle : XLGLRendererBase
- (void) particleRenderPixeBuffer:(CVPixelBufferRef) destinationPixelBuffer
                 usingSouceBuffer:(CVPixelBufferRef) sourcePixelBuffer;
@end
