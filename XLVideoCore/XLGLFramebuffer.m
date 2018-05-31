//
//  XLGLFramebuffer.m
//  XLVideoCore
//
//  Created by 周晓林 on 2018/5/31.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#import "XLGLFramebuffer.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "XLGLContext.h"
@interface XLGLFramebuffer()
{
    GLuint _offscreenBufferHandle;
}
@end
@implementation XLGLFramebuffer
- (instancetype)init{
    if (!(self = [super init])) {
        return nil;
    }
    
    glGenFramebuffers(1, &_offscreenBufferHandle);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _offscreenBufferHandle);
    
    return self;
}

- (void)render:(CVPixelBufferRef)pixelBuffer{
    CVOpenGLESTextureRef destTexture = NULL;
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
                                                       &destTexture);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _offscreenBufferHandle);
    glViewport(0, 0, (int)CVPixelBufferGetWidth(pixelBuffer), (int)CVPixelBufferGetHeight(pixelBuffer));
    
    
    
    // Attach the destination texture as a color attachment to the off screen frame buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(destTexture), 0);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
}
- (void)dealloc{
    if (_offscreenBufferHandle) {
        glDeleteFramebuffers(1, &_offscreenBufferHandle);
        _offscreenBufferHandle = 0;
    }
    
}
@end
