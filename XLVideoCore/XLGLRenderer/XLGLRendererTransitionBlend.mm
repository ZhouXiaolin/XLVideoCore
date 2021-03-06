//
//  XLGLRendererTransitionBlend.m
//  XLVideoCore
//
//  Created by 周晓林 on 2018/6/1.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#import "XLGLRendererTransitionBlend.h"
#include "XLGLProgram.hpp"
using namespace XLSimple2D;
const char* kXLCompositorBlendFragmentShader = SHADER_STRING
(
 precision mediump float;
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform vec4 color;
 uniform float factor;
 uniform float brightness;
 void main()
 {
     vec4 texture1 = texture2D(inputImageTexture, textureCoordinate);
     vec4 texture2 = texture2D(inputImageTexture2, textureCoordinate);
     vec4 mixColor;
     mixColor = mix(texture1,texture2,mix(step(0.5,texture2.a),factor,step(0.0,factor)))*color;
     
     
     gl_FragColor = vec4(vec3(brightness) + mixColor.rgb,1.0);
 }
 );


@interface XLGLRendererTransitionBlend()
{
    GLuint blendPositionAttribute,blendTextureCoordinateAttribute;
    GLuint blendInputTextureUniform,blendInputTextureUniform2;
    GLuint blendProjectionUniform,blendTransformUniform,blendColorUniform,blendFactorUniform,blendBrightnessUniform;
    
    ksMatrix4 _modelViewMatrix;
    ksMatrix4 _projectionMatrix;
    
    
    std::shared_ptr<XLGLProgram> _program;

    std::shared_ptr<XLGLFramebuffer> _framebuffer;
}
@end
@implementation XLGLRendererTransitionBlend
- (instancetype)init{
    if (!(self = [super init])) {
        return nil;
    }
    
    [XLGLContext useContext];

    
    
    _framebuffer = std::make_shared<XLGLFramebuffer>();
    
    [self loadShaders];
        
    return self;
}
- (void) loadShaders{
    _program = std::make_shared<XLGLProgram>(kXLCompositorVertexShader,kXLCompositorBlendFragmentShader);
    _program->link();
    
    blendPositionAttribute = _program->attribute("position");
    blendTextureCoordinateAttribute = _program->attribute("inputTextureCoordinate");
    blendProjectionUniform = _program->uniform("projection");
    blendInputTextureUniform = _program->uniform("inputImageTexture");
    blendInputTextureUniform2 = _program->uniform("inputImageTexture2");
    blendTransformUniform = _program->uniform("renderTransform");
    blendColorUniform = _program->uniform("color");
    blendFactorUniform = _program->uniform("factor");
    blendBrightnessUniform = _program->uniform("brightness");
}

- (void)renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer usingForegroundSourceBuffer:(CVPixelBufferRef)foregroundPixelBuffer andBackgroundSourceBuffer:(CVPixelBufferRef)backgroundPixelBuffer forTweenFactor:(float)tween type:(unsigned int) type
{
    
    [XLGLContext useContext];

    _framebuffer->active(destinationPixelBuffer);
    CVOpenGLESTextureRef foregroundTexture = [self customTextureForPixelBuffer:foregroundPixelBuffer];
    
    CVOpenGLESTextureRef backgroundTexture = [self customTextureForPixelBuffer:backgroundPixelBuffer];
    
    
    
    {
        
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
        
        
        int transitionType = type;
        if (transitionType == 5 || transitionType == 6 || transitionType == 7 ) { // 淡入
            
            _program->use();
            
            
            glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
            glClear(GL_COLOR_BUFFER_BIT);
            
            
            
            
            ksMatrixLoadIdentity(&_modelViewMatrix);
            
            glUniformMatrix4fv(blendTransformUniform, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
            
            
            
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
            
            
            ksMatrixLoadIdentity(&_projectionMatrix);
            glUniformMatrix4fv(blendProjectionUniform, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
            
            glUniform1i(blendInputTextureUniform, 0);
            glUniform1i(blendInputTextureUniform2, 1);
            
            
            glUniform4f(blendColorUniform, 1.0, 1.0, 1.0, 1.0);
            
            
            if (transitionType == 5) {
                glUniform1f(blendBrightnessUniform, 0.0);
                glUniform1f(blendFactorUniform, tween);
                
            }else if (transitionType == 6){
                glUniform1f(blendBrightnessUniform, 2.0*(fabs(tween-0.5)-0.5));
                glUniform1f(blendFactorUniform, tween>0.5?1.0:0.0);
                
                
            }else if(transitionType == 7){
                glUniform1f(blendBrightnessUniform, 2.0*(0.5-fabs(tween-0.5)));
                glUniform1f(blendFactorUniform, tween>0.5?1.0:0.0);
                
            }
            
            glVertexAttribPointer(blendPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData1);
            glEnableVertexAttribArray(blendPositionAttribute);
            
            glVertexAttribPointer(blendTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData1);
            glEnableVertexAttribArray(blendTextureCoordinateAttribute);
            
            // Draw the foreground frame
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
            
        }
        
    }
    
    // 其他效果
    
    CFRelease(foregroundTexture);
    CFRelease(backgroundTexture);
    
    
    
    
    
}
@end
