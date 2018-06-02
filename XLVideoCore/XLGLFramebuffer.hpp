//
//  XLGLFramebuffer.h
//  XLVideoCore
//
//  Created by 周晓林 on 2018/5/31.
//  Copyright © 2018年 Solaren. All rights reserved.
//


#ifndef XLGLFramebuffer_hpp
#define XLGLFramebuffer_hpp

#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#include <CoreVideo/CVPixelBuffer.h>
namespace Simple2D {
    class XLGLFramebuffer {
    public:
        XLGLFramebuffer();
        ~XLGLFramebuffer();
        void render(CVPixelBufferRef destinationPixelBuffer);
    private:
        GLuint framebuffer;
    };
}
#endif
