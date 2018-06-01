//
//  XLGLRendererBase.h
//  XLVideoCore
//
//  Created by 周晓林 on 2018/6/1.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "ksVector.h"
#include "ksMatrix.h"
#import "XLGLContext.h"
#import "XLGLProgram.h"
#import "XLGLFramebuffer.h"
#import "XLScene.h"
#import "XLTexturePool.h"

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

extern NSString* const kXLCompositorVertexShader;
extern NSString* const kXLCompositorFragmentShader;

@interface XLGLRendererBase : NSObject
@property (nonatomic,assign) CGSize videoSize;
- (CVOpenGLESTextureRef) customTextureForPixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (CVOpenGLESTextureRef) imageTextureForPixelBuffer:(CVPixelBufferRef) pixelBuffer;
- (CVOpenGLESTextureRef) chromaTextureForPixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (CVOpenGLESTextureRef) lumaTextureForPixelBuffer:(CVPixelBufferRef)pixelBuffer;
@end
