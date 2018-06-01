//
//  XLGLParticleRenderer.m
//  XLVideoCore
//
//  Created by 周晓林 on 2018/5/31.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#import "XLGLRendererParticle.h"
#include "ParticleSystem.h"
#include "XLGLProgram.hpp"
using namespace Simple2D;

NSString* const kXLParticleVertexShader = SHADER_STRING
(
 attribute vec4 position;
 attribute vec2 inputTextureCoordinate;
 attribute vec4 inputTextureColor;
 
 varying vec2 textureCoordinate;
 varying vec4 textureColor;
 
 void main(){
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate;
     textureColor = inputTextureColor;
 }
 );

NSString* const kXLParticleFragmentShader = SHADER_STRING
(
 precision mediump float;
 varying highp vec2 textureCoordinate;
 varying highp vec4 textureColor;
 uniform sampler2D inputImageTexture;
 void main(){
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate) * textureColor;
 }
 );

@interface XLGLRendererParticle()
{
    GLuint particlePositionAttribute,particleTextureCoordinateAttribute,particleTextureColorAttribute;
    GLuint particleInputTextureUniform;
    
    std::shared_ptr<XLGLProgram> _program;
    
    XLGLFramebuffer* _framebuffer;
    
    ParticleSystemManager particleSystemManager;
    ParticleSystem* fire1PS;
    VertexData* vertexData;
    
    ResizeVector<Vec2> vDefaultTexcoords;
    ResizeVector<int> vDefaultIndices;
}
@end
@implementation XLGLRendererParticle
- (instancetype)init{
    if (!(self = [super init])) {
        return nil;
    }
    
    vertexData = new VertexData();
    
    fire1PS = new ParticleSystem;
    
    NSString* fire2PlistPath = [[NSBundle mainBundle] pathForResource:@"XLVideoCore.bundle/fallenLeaves" ofType:@"plist"];
    NSString* fire2ImagePath = [[NSBundle mainBundle] pathForResource:@"XLVideoCore.bundle/fallenLeaves" ofType:@"png"];
    fire1PS->initWithPlist([fire2PlistPath UTF8String]);
    fire1PS->setTexture([fire2ImagePath UTF8String]);
    
    fire1PS->getEmitter()->setEmitPos(Vec2(200, 250));
    fire1PS->getEmitter()->getParticleEffect()->motionMode = MotionMode::MOTION_MODE_FREE;
    
    particleSystemManager.appendParticleSystem(fire1PS);
    
    [XLGLContext useContext];
    
    _framebuffer = [[XLGLFramebuffer alloc] init];
    
    [self loadShaders];
        
    return self;
}
- (void) loadShaders{
//    _program = [[XLGLProgram alloc] initWithVertexShaderString:kXLParticleVertexShader fragmentShaderString:kXLParticleFragmentShader];
//    [_program link];
    _program = std::make_shared<XLGLProgram>(kXLParticleVertexShader.UTF8String, kXLParticleFragmentShader.UTF8String);
    
    particlePositionAttribute = _program->attribute("position");
    particleTextureColorAttribute = _program->attribute("inputTextureColor");
    particleTextureCoordinateAttribute = _program->attribute("inputTextureCoordinate");
    particleInputTextureUniform = _program->uniform("inputImageTexture");
}

- (bool) setDefaultTexcoords:(int) new_size{
    int old_size = (int)vDefaultTexcoords.vector.size();
    if ( old_size >= new_size ) return false;
    
    int append_size = new_size - old_size;
    assert(append_size % 4 == 0);
    
    vDefaultTexcoords.resize(new_size);
    
    append_size /= 4;
    int begin_index = old_size;
    for ( int i = 0; i < append_size; i++ ) {
        vDefaultTexcoords[begin_index++].set(0, 0);
        vDefaultTexcoords[begin_index++].set(0, 1);
        vDefaultTexcoords[begin_index++].set(1, 1);
        vDefaultTexcoords[begin_index++].set(1, 0);
    }
    return true;
}

- (bool) setDefaultIndices:(int) new_size{
    int old_size = (int)vDefaultIndices.vector.size();
    if ( old_size >= new_size ) return false;
    
    int append_size = new_size - old_size;
    assert(append_size % 6 == 0);
    
    vDefaultIndices.resize(new_size);
    
    append_size /= 6;
    int begin_index = old_size;
    int begin_vertex_index = old_size * 4 / 6;
    for ( int i = 0; i < append_size; i++ ) {
        vDefaultIndices[begin_index++] = begin_vertex_index + 0;
        vDefaultIndices[begin_index++] = begin_vertex_index + 2;
        vDefaultIndices[begin_index++] = begin_vertex_index + 1;
        vDefaultIndices[begin_index++] = begin_vertex_index + 0;
        vDefaultIndices[begin_index++] = begin_vertex_index + 3;
        vDefaultIndices[begin_index++] = begin_vertex_index + 2;
        begin_vertex_index += 4;
    }
    return true;
}
- (void) particleRenderPixeBuffer:(CVPixelBufferRef) destinationPixelBuffer
                 usingSouceBuffer:(CVPixelBufferRef) sourcePixelBuffer

{
    
    [XLGLContext useContext];
    
//    [_program use];
    _program->use();
    [_framebuffer render:destinationPixelBuffer];
    
    
    
    {
        
        
        glEnable(GL_BLEND);
        
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        
        
        
        CVOpenGLESTextureRef sourceTexture = [self customTextureForPixelBuffer:sourcePixelBuffer];
        
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(CVOpenGLESTextureGetTarget(sourceTexture), CVOpenGLESTextureGetName(sourceTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        glUniform1i(particleInputTextureUniform, 0);
        
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
        
        GLfloat quadTextureColor []  = {
            1.0,1.0,1.0,1.0,
            1.0,1.0,1.0,1.0,
            1.0,1.0,1.0,1.0,
            1.0,1.0,1.0,1.0,
            
        };
        
        
        
        glVertexAttribPointer(particlePositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData1);
        glEnableVertexAttribArray(particlePositionAttribute);
        
        glVertexAttribPointer(particleTextureColorAttribute, 4, GL_FLOAT, 0,0, quadTextureColor);
        glEnableVertexAttribArray(particleTextureColorAttribute);
        
        glVertexAttribPointer(particleTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData1);
        glEnableVertexAttribArray(particleTextureCoordinateAttribute);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        
        std::vector<RenderUnit> units;
        particleSystemManager.update(0.01);
        particleSystemManager.render(units);
                
        for(auto unit : units){
            
            vertexData->positions.resize(unit.nPositionCount);
            vertexData->indices.resize(unit.nIndexCount);
            vertexData->texcoords.resize(unit.nPositionCount);
            vertexData->colors.resize(unit.nPositionCount);
            
            Matrix4 ortho = Matrix4::ortho(0, self.videoSize.width, self.videoSize.height, 0, -1, 1);
            Matrix4 tranform = Matrix4::makeTransform(Vec3(0, self.videoSize.height, 0), Vec3(1, -1, 1));
            Matrix4 mTransformMatrix = ortho * tranform;
            
            for (int i = 0; i<unit.nPositionCount; i++) {
                vertexData->positions[i] = mTransformMatrix * unit.pPositions[i];
                vertexData->colors[i] = unit.color[i];
            }
            
            [self setDefaultIndices:unit.nIndexCount];
            [self setDefaultTexcoords:unit.nPositionCount];
            
            
            
            GLuint imageTexture = unit.texture->texture;
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, imageTexture);

            
            
            glUniform1i(particleInputTextureUniform, 0);
            
            glVertexAttribPointer(particlePositionAttribute, 3, GL_FLOAT, 0, sizeof(Vec3),&vertexData->positions[0]);
            glEnableVertexAttribArray(particlePositionAttribute);
            //
            
            glVertexAttribPointer(particleTextureCoordinateAttribute, 2, GL_FLOAT, 0, sizeof(Vec2), &vDefaultTexcoords[0]);
            glEnableVertexAttribArray(particleTextureCoordinateAttribute);
            //
            glVertexAttribPointer(particleTextureColorAttribute, 4, GL_FLOAT, 0, sizeof(Color), &vertexData->colors[0]);
            glEnableVertexAttribArray(particleTextureColorAttribute);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            glDrawElements(GL_TRIANGLES, unit.nIndexCount, GL_UNSIGNED_INT, &vDefaultIndices[0]);
            
            
            
        }
        glFlush();
        
        
        
    }
}
@end
