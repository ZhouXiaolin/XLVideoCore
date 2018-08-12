//
//  XLGLSimpleTransitionRenderer.m
//  XLVideoCore
//
//  Created by 周晓林 on 2018/5/31.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#import "XLGLRendererTransitionSimple.h"
#include "XLGLProgram.hpp"
using namespace XLSimple2D;

const char* kXLCompositorMotionBlurFragmentShader = SHADER_STRING
(
 precision mediump float;
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 
 uniform vec4 color;
 void main(){
     vec2 dir = vec2(0.5) - textureCoordinate;
     float dist = length(dir);
     dir /= dist;
     
     
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate)*color;
     
     vec4 sum = textureColor;
     
     gl_FragColor = textureColor;
    
     
 }
 );


@interface XLGLRendererTransitionSimple()
{
    GLuint normalPositionAttribute,normalTextureCoordinateAttribute;
    GLuint normalInputTextureUniform;
    GLuint normalProjectionUniform,normalTransformUniform,normalColorUniform;
    
    
    ksMatrix4 _modelViewMatrix;
    ksMatrix4 _projectionMatrix;
    
    
    std::shared_ptr<XLGLProgram> _program;
    
//    XLGLFramebuffer* _framebuffer;
    std::shared_ptr<XLGLFramebuffer> _framebuffer;
}
@end
@implementation XLGLRendererTransitionSimple
- (instancetype)init{
    if (!(self = [super init])) {
        return nil;
    }
    
    [XLGLContext useContext];

    
    
//    _framebuffer = [[XLGLFramebuffer alloc] init];
    _framebuffer = std::make_shared<XLGLFramebuffer>();
    
    [self loadShaders];
    
    
    return self;
}
- (void) loadShaders {
    
    _program = std::make_shared<XLGLProgram>(kXLCompositorVertexShader, kXLCompositorMotionBlurFragmentShader);
    _program->link();
    normalPositionAttribute = _program->attribute("position");
    normalTextureCoordinateAttribute = _program->attribute("inputTextureCoordinate");
    normalProjectionUniform = _program->uniform("projection");
    normalInputTextureUniform = _program->uniform("inputImageTexture");
    normalTransformUniform = _program->uniform("renderTransform");
    normalColorUniform = _program->uniform("color");
}

- (void)renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer usingForegroundSourceBuffer:(CVPixelBufferRef)foregroundPixelBuffer andBackgroundSourceBuffer:(CVPixelBufferRef)backgroundPixelBuffer forTweenFactor:(float)tween type:(unsigned int) type
{
    
    [XLGLContext useContext];

    
    _framebuffer->active(destinationPixelBuffer);
    CVOpenGLESTextureRef foregroundTexture = [self customTextureForPixelBuffer:foregroundPixelBuffer];
    
    CVOpenGLESTextureRef backgroundTexture = [self customTextureForPixelBuffer:backgroundPixelBuffer];
    
    
    
    {
        
        
        int transitionType = type;
        if (transitionType <= 4) {
            _program->use();            
            
            glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
            glClear(GL_COLOR_BUFFER_BIT);
            
            ksMatrixLoadIdentity(&_modelViewMatrix);
            
            glUniformMatrix4fv(normalTransformUniform, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
            
            {
                
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
                
                if (transitionType == 1) {
                    ksMatrixTranslate(&_projectionMatrix, -tween*2, 0, 0);
                }else if (transitionType == 2){
                    ksMatrixTranslate(&_projectionMatrix, tween*2, 0, 0);
                }else if (transitionType == 3) {
                    ksMatrixTranslate(&_projectionMatrix, 0, -tween*2, 0);
                }else if (transitionType == 4){
                    ksMatrixTranslate(&_projectionMatrix, 0, tween*2, 0);
                }
                
                
                glUniformMatrix4fv(normalProjectionUniform, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
                
                
                glActiveTexture(GL_TEXTURE0);
                glBindTexture(CVOpenGLESTextureGetTarget(foregroundTexture), CVOpenGLESTextureGetName(foregroundTexture));
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
                
                glUniform1i(normalInputTextureUniform, 0);
                glUniform4f(normalColorUniform, 1.0, 1.0, 1.0, 1.0);
                
                glVertexAttribPointer(normalPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData1);
                glEnableVertexAttribArray(normalPositionAttribute);
                
                glVertexAttribPointer(normalTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData1);
                glEnableVertexAttribArray(normalTextureCoordinateAttribute);
                
                // Draw the foreground frame
                glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
                
                
            }
            
            {
                
                GLfloat quadVertexData2 [] = {
                    -1.0, 1.0,
                    1.0, 1.0,
                    -1.0, -1.0,
                    1.0, -1.0,
                };
                GLfloat quadTextureData2 [] = { //纹理坐标
                    0.0f, 1.0f,
                    1.0f, 1.0f,
                    0.0f, 0.0f,
                    1.0f, 0.0f,
                };
                ksMatrixLoadIdentity(&_projectionMatrix);
                
                if (transitionType == 1) {//左推
                    
                    ksMatrixTranslate(&_projectionMatrix, 2.0-tween*2, 0, 0);
                }else if (transitionType == 2){ // 右推
                    
                    ksMatrixTranslate(&_projectionMatrix, -2.0+tween*2, 0, 0);
                    
                }else if (transitionType == 3) {// 上推
                    
                    ksMatrixTranslate(&_projectionMatrix, 0, 2.0-tween*2, 0);
                }else if (transitionType == 4){ // 下推
                    
                    ksMatrixTranslate(&_projectionMatrix, 0, -2.0+tween*2, 0);
                    
                }
                
                
                
                glUniformMatrix4fv(normalProjectionUniform, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
                
                
                glActiveTexture(GL_TEXTURE1);
                glBindTexture(CVOpenGLESTextureGetTarget(backgroundTexture), CVOpenGLESTextureGetName(backgroundTexture));
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
                
                glUniform1i(normalInputTextureUniform, 1);
                glUniform4f(normalColorUniform, 1.0, 1.0, 1.0, 1.0);
                
                glVertexAttribPointer(normalPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData2);
                glEnableVertexAttribArray(normalPositionAttribute);
                
                glVertexAttribPointer(normalTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData2);
                glEnableVertexAttribArray(normalTextureCoordinateAttribute);
                
                
                // Draw the background frame
                glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
            }
            glFlush();
            
            
        }
       
        
    }
        
    CFRelease(foregroundTexture);
    CFRelease(backgroundTexture);
    
    
    
    
    
}



@end
