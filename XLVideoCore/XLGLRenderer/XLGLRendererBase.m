//
//  XLGLRendererBase.m
//  XLVideoCore
//
//  Created by 周晓林 on 2018/6/1.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#import "XLGLRendererBase.h"
// 基类
NSString*  const kRDCompositorVertexShader = SHADER_STRING
(
 attribute vec4 position;
 attribute vec2 inputTextureCoordinate;
 uniform mat4 projection;
 uniform mat4 renderTransform;
 varying vec2 textureCoordinate;
 varying vec2 positionorign;
 void main()
 {
     gl_Position = projection * renderTransform * position;
     textureCoordinate = inputTextureCoordinate;
     positionorign = position.xy;
 }
 );

NSString* const kRDCompositorFragmentShader = SHADER_STRING
(
 precision mediump float;
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform vec4 color;
 uniform sampler2D inputImageTexture2;
 void main(){
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate)*color;
     vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate);
     float newAlpha = dot(textureColor2.rgb,vec3(0.333333334)) *textureColor2.a;
     
     if(newAlpha<0.5){
         gl_FragColor = textureColor;
     }else{
         gl_FragColor = vec4(0.0,0.0,0.0,0.0);
     }
     
 }
 );

@interface XLGLRendererBase()
{
    
}
@end
@implementation XLGLRendererBase
- (CVOpenGLESTextureRef)customTextureForPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    CVOpenGLESTextureRef bgraTexture = NULL;
    CVReturn err;
    
    
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       [[XLGLContext context] coreVideoTextureCache],
                                                       pixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RGBA,
                                                       (int)CVPixelBufferGetWidth(pixelBuffer),
                                                       (int)CVPixelBufferGetHeight(pixelBuffer),
                                                       GL_BGRA,
                                                       GL_UNSIGNED_BYTE,
                                                       0,
                                                       &bgraTexture);
    
    if (!bgraTexture || err) {
        NSLog(@"Error creating BGRA texture using CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    //bail:
    return bgraTexture;
}

- (CVOpenGLESTextureRef)lumaTextureForPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    CVOpenGLESTextureRef lumaTexture = NULL;
    CVReturn err;
    
    
    
    
    
    
    // CVOpenGLTextureCacheCreateTextureFromImage will create GL texture optimally from CVPixelBufferRef.
    // Y
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       [[XLGLContext context] coreVideoTextureCache],
                                                       pixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RED_EXT,
                                                       (int)CVPixelBufferGetWidth(pixelBuffer),
                                                       (int)CVPixelBufferGetHeight(pixelBuffer),
                                                       GL_RED_EXT,
                                                       GL_UNSIGNED_BYTE,
                                                       0,
                                                       &lumaTexture);
    
    if (!lumaTexture || err) {
        NSLog(@"Error at creating luma texture using CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
bail:
    return lumaTexture;
}

- (CVOpenGLESTextureRef)chromaTextureForPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    CVOpenGLESTextureRef chromaTexture = NULL;
    CVReturn err;
    
    
    // CVOpenGLTextureCacheCreateTextureFromImage will create GL texture optimally from CVPixelBufferRef.
    // UV
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       [[XLGLContext context] coreVideoTextureCache],
                                                       pixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RG_EXT,
                                                       (int)CVPixelBufferGetWidthOfPlane(pixelBuffer, 1),
                                                       (int)CVPixelBufferGetHeightOfPlane(pixelBuffer, 1),
                                                       GL_RG_EXT,
                                                       GL_UNSIGNED_BYTE,
                                                       1,
                                                       &chromaTexture);
    
    if (!chromaTexture || err) {
        NSLog(@"Error at creating chroma texture using CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
bail:
    return chromaTexture;
}
- (CVOpenGLESTextureRef) imageTextureForPixelBuffer:(CVPixelBufferRef) pixelBuffer
{
    CVOpenGLESTextureRef bgraTexture = NULL;
    CVReturn err;
    
    
    {
        int width = (int)CVPixelBufferGetWidth(pixelBuffer);
        int height = (int)CVPixelBufferGetHeight(pixelBuffer);
        
        
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           [[XLGLContext context] coreVideoTextureCache],
                                                           pixelBuffer,
                                                           NULL,
                                                           GL_TEXTURE_2D,
                                                           GL_RGBA,
                                                           width,
                                                           height,
                                                           GL_RGBA,
                                                           GL_UNSIGNED_BYTE,
                                                           0,
                                                           &bgraTexture);
        
        if (!bgraTexture || err) {
            NSLog(@"Error creating rgba texture using CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
    }
    
bail:
    return bgraTexture;
    
    
}
@end
