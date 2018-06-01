//
//  XLGLSimpleTransitionRenderer.m
//  XLVideoCore
//
//  Created by 周晓林 on 2018/5/31.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#import "XLGLRendererTransitionSimple.h"
@interface XLGLRendererTransitionSimple()
{
    GLuint normalPositionAttribute,normalTextureCoordinateAttribute;
    GLuint normalInputTextureUniform,normalInputTextureUniform2;
    GLuint normalProjectionUniform,normalTransformUniform,normalColorUniform;
    
    
    ksMatrix4 _modelViewMatrix;
    ksMatrix4 _projectionMatrix;
    
    
    XLGLContext* context;
    XLGLProgram* _program;
    
    XLGLFramebuffer* _framebuffer;
}
@end
@implementation XLGLRendererTransitionSimple
- (instancetype)init{
    if (!(self = [super init])) {
        return nil;
    }
    context = [XLGLContext context];
    [context useAsCurrentContext];
    
    
    _framebuffer = [[XLGLFramebuffer alloc] init];
    
    [self loadShaders];
    
    [EAGLContext setCurrentContext:nil];
    
    return self;
}
- (void) loadShaders {
    _program = [[XLGLProgram alloc] initWithVertexShaderString:kRDCompositorVertexShader fragmentShaderString:kRDCompositorFragmentShader];
    [_program link];
    
    
    normalPositionAttribute = [_program attributeIndex: @"position"];
    normalTextureCoordinateAttribute = [_program attributeIndex: @"inputTextureCoordinate"];
    normalProjectionUniform = [_program uniformIndex: @"projection"];
    normalInputTextureUniform = [_program uniformIndex: @"inputImageTexture"];
    normalInputTextureUniform2 = [_program uniformIndex: @"inputImageTexture2"];
    normalTransformUniform = [_program uniformIndex: @"renderTransform"];
    normalColorUniform = [_program uniformIndex: @"color"];
}

- (void)renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer usingForegroundSourceBuffer:(CVPixelBufferRef)foregroundPixelBuffer andBackgroundSourceBuffer:(CVPixelBufferRef)backgroundPixelBuffer forTweenFactor:(float)tween type:(unsigned int) type
{
    
    [context useAsCurrentContext];
    
    
    [_framebuffer render:destinationPixelBuffer];
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
        if (transitionType <= 4) {
            //            glUseProgram(self.program);
            [_program use];
            // Set the render transform
            
            
            
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
    
    // 其他效果
    
    CFRelease(foregroundTexture);
    CFRelease(backgroundTexture);
    
    
    
    
    
}



@end
