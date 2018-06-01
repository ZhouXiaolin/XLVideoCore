//
//  XLGLMaskTransitionRenderer.m
//  XLVideoCore
//
//  Created by 周晓林 on 2018/5/31.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#import "XLGLRendererTransitionMask.h"
NSString*  const  kXLCompositorPassThroughMaskFragmentShader = SHADER_STRING
(
 precision mediump float;
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform sampler2D inputImageTexture3;
 uniform float factor;
 varying highp vec2 textureCoordinate;
 void main(){
     
     vec4 texture1 = texture2D(inputImageTexture, textureCoordinate);//foreground
     vec4 texture2 = texture2D(inputImageTexture2, textureCoordinate);//background
     vec4 texture3 = texture2D(inputImageTexture3, textureCoordinate);//mask
     
     float newAlpha = dot(texture3.rgb,vec3(0.333333334)) *texture3.a;
     newAlpha = step(factor,newAlpha);
     vec4 t = vec4(texture1.rgb,newAlpha);
     
     gl_FragColor = vec4(mix(texture2.rgb,t.rgb,t.a),texture2.a);
 }
 );
@interface XLGLRendererTransitionMask()
{
    GLuint maskPositionAttribute,maskTextureCoordinateAttribute;
    GLuint maskInputTextureUniform,maskInputTextureUniform2,maskInputTextureUniform3;
    GLuint maskProjectionUniform,maskTransformUniform,maskFactorUniform;
    
    ksMatrix4 _modelViewMatrix;
    ksMatrix4 _projectionMatrix;
    
    
    XLGLProgram* _program;
    
    XLGLFramebuffer* _framebuffer;
}
@end
@implementation XLGLRendererTransitionMask
- (instancetype)init{
    if (!(self = [super init])) {
        return nil;
    }
    [XLGLContext useContext];

    
    
    _framebuffer = [[XLGLFramebuffer alloc] init];
    
    [self loadShaders];
    
    
    return self;
}
- (void) loadShaders{
    _program = [[XLGLProgram alloc] initWithVertexShaderString:kXLCompositorVertexShader fragmentShaderString:kXLCompositorPassThroughMaskFragmentShader];
    [_program link];
    
    maskPositionAttribute = [_program attributeIndex: @"position"];
    maskTextureCoordinateAttribute = [_program attributeIndex: @"inputTextureCoordinate"];
    maskProjectionUniform = [_program uniformIndex: @"projection"];
    maskInputTextureUniform = [_program uniformIndex: @"inputImageTexture"];
    maskInputTextureUniform2 = [_program uniformIndex: @"inputImageTexture2"];
    maskInputTextureUniform3 = [_program uniformIndex: @"inputImageTexture3"];
    maskTransformUniform = [_program uniformIndex: @"renderTransform"];
    maskFactorUniform = [_program uniformIndex: @"factor"];
}
- (void) renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer
usingForegroundSourceBuffer:(CVPixelBufferRef)foregroundPixelBuffer
 andBackgroundSourceBuffer:(CVPixelBufferRef)backgroundPixelBuffer
          andMaskImagePath:(NSURL *) path
            forTweenFactor:(float)tween
{
    
    [XLGLContext useContext];

    [_program use];
    
    
    [_framebuffer render:destinationPixelBuffer];
    
    
    {
        CVOpenGLESTextureRef foregroundTexture = [self customTextureForPixelBuffer:foregroundPixelBuffer];
        if (!foregroundTexture) {return;}
        CVOpenGLESTextureRef backgroundTexture = [self customTextureForPixelBuffer:backgroundPixelBuffer];
        if (!backgroundTexture) {return;}
        // Y planes of foreground and background frame are used to render the Y plane of the destination frame
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(CVOpenGLESTextureGetTarget(foregroundTexture), CVOpenGLESTextureGetName(foregroundTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(CVOpenGLESTextureGetTarget(backgroundTexture), CVOpenGLESTextureGetName(backgroundTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        
        XLTexture* imageBuffer = [XLTexturePool.sharedInstance fetchImageTextureForPath:path];
        GLuint imageTexture = imageBuffer.texture;
        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_2D, imageTexture);

        
        
        
        
        [_program use];
        
        ksMatrixLoadIdentity(&_modelViewMatrix);
        
        
        ksMatrixLoadIdentity(&_projectionMatrix);
        
        
        
        
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        
        GLfloat quadVertexData1 [] = {
            -1.0, 1.0,
            1.0, 1.0,
            -1.0, -1.0,
            1.0, -1.0,
        };
        
        GLfloat quadTextureData1 [] = { //纹理坐标
            0.0f, 1.0f,
            1.0f, 1.0f,
            0.0f, 0.0f,
            1.0f, 0.0f,
        };
        
        glUniformMatrix4fv(maskTransformUniform, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
        glUniformMatrix4fv(maskProjectionUniform, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
        
        glUniform1i(maskInputTextureUniform, 0);
        glUniform1i(maskInputTextureUniform2, 1);
        glUniform1i(maskInputTextureUniform3, 2);
        glUniform1f(maskFactorUniform, tween);
        glVertexAttribPointer(maskPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData1);
        glEnableVertexAttribArray(maskPositionAttribute);
        
        glVertexAttribPointer(maskTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData1);
        glEnableVertexAttribArray(maskTextureCoordinateAttribute);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        
        glFlush();
        
        CFRelease(foregroundTexture);
        CFRelease(backgroundTexture);
        
    }
    
}

@end
