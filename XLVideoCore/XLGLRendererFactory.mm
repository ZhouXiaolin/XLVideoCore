//
//  XLVideoCompositorRenderer.m
//  XLVideoCore
//
//  Created by 周晓林 on 2018/5/28.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#import "XLGLRendererFactory.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <Photos/Photos.h>
#import "XLTexturePool.h"
#include "ksVector.h"
#include "ksMatrix.h"
#include "ParticleSystem.h"
using namespace Simple2D;

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)




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

NSString* const kRDParticleVertexShader = SHADER_STRING
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

NSString* const kRDParticleFragmentShader = SHADER_STRING
(
 precision mediump float;
 varying highp vec2 textureCoordinate;
 varying highp vec4 textureColor;
 uniform sampler2D inputImageTexture;
 void main(){
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate) * textureColor;
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

NSString*  const  kRDCompositorBlendFragmentShader = SHADER_STRING
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

NSString*  const  kRDCompositorPassThroughMaskFragmentShader = SHADER_STRING
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


@interface XLGLRendererFactory ()
{
    GLuint normalPositionAttribute,normalTextureCoordinateAttribute;
    GLuint normalInputTextureUniform,normalInputTextureUniform2;
    GLuint normalProjectionUniform,normalTransformUniform,normalColorUniform;
    
    GLuint blendPositionAttribute,blendTextureCoordinateAttribute;
    GLuint blendInputTextureUniform,blendInputTextureUniform2;
    GLuint blendProjectionUniform,blendTransformUniform,blendColorUniform,blendFactorUniform,blendBrightnessUniform;
    
    GLuint maskPositionAttribute,maskTextureCoordinateAttribute;
    GLuint maskInputTextureUniform,maskInputTextureUniform2,maskInputTextureUniform3;
    GLuint maskProjectionUniform,maskTransformUniform,maskFactorUniform;
    
    GLuint particlePositionAttribute,particleTextureCoordinateAttribute,particleTextureColorAttribute;
    GLuint particleInputTextureUniform;
    
    GLuint vertShader, fragShader, blendFragShader, maskFragShader,particleVertShader,particleFragShader;
    
    ParticleSystemManager particleSystemManager;
    ParticleSystem* fire1PS;
    
    
    ksMatrix4 _modelViewMatrix;
    ksMatrix4 _projectionMatrix;
    
    VertexData* vertexData;
    
    ResizeVector<Vec2> vDefaultTexcoords;
    ResizeVector<int> vDefaultIndices;
    
    
    
    
}
@property GLuint program;
@property GLuint blendProgram;
@property GLuint maskProgram;
@property GLuint particleProgram;

@property CVOpenGLESTextureCacheRef videoTextureCache;
@property EAGLContext *currentContext;
@property GLuint offscreenBufferHandle;
@end

@implementation XLGLRendererFactory

+ (XLGLRendererFactory *)sharedVideoCompositorRender{
    static XLGLRendererFactory* renderer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        renderer = [[[self class] alloc] init];
        NSLog(@"%s",__func__);
    });
    return renderer;
}

- (id)init
{
    self = [super init];
    if(self) {
        
        
        //初始化一个粒子效果
        
        vertexData = new VertexData();
        
        fire1PS = new ParticleSystem;
        
        NSString* fire2PlistPath = [[NSBundle mainBundle] pathForResource:@"XLVideoCore.bundle/fallenLeaves" ofType:@"plist"];
        NSString* fire2ImagePath = [[NSBundle mainBundle] pathForResource:@"XLVideoCore.bundle/fallenLeaves" ofType:@"png"];
        fire1PS->initWithPlist([fire2PlistPath UTF8String]);
        fire1PS->setTexture([fire2ImagePath UTF8String]);
        
        fire1PS->getEmitter()->setEmitPos(Vec2(200, 250));
        fire1PS->getEmitter()->getParticleEffect()->motionMode = MotionMode::MOTION_MODE_FREE;
        
        particleSystemManager.appendParticleSystem(fire1PS);
        
        
        
        _currentContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        [EAGLContext setCurrentContext:_currentContext];
        
        [self setupOffscreenRenderContext];
        
        
        [self loadShaders];
        
        [EAGLContext setCurrentContext:nil];
    }
    
    return self;
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

- (void) clear
{
    [XLTexturePool.sharedInstance clear];    
}
- (void)dealloc
{
    //    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"%s",__func__);
    if (_videoTextureCache) {
        CFRelease(_videoTextureCache);
    }
    if (_offscreenBufferHandle) {
        glDeleteFramebuffers(1, &_offscreenBufferHandle);
        _offscreenBufferHandle = 0;
    }
    
    if (_program) {
        glDeleteProgram(_program);
    }
    if (_blendProgram) {
        glDeleteProgram(_blendProgram);
    }
    if (_maskProgram) {
        glDeleteProgram(_maskProgram);
    }
    
    [EAGLContext setCurrentContext:nil];
}



- (CGAffineTransform)transformFromAsset:(XLAsset*) asset sourceSize:(CGSize) sourceSize destinationSize:(CGSize)destinationSize textureData:(GLfloat*)textureData{
    float x = asset.crop.origin.x;
    float y = asset.crop.origin.y;
    float w = asset.crop.size.width;
    float h = asset.crop.size.height;
    
    
    float angle = (asset.rotate+360)/180.0*M_PI;
    
    
    BOOL sR = NO;
    float angleOrign = 0;
    
    
    if (asset.type == XLAssetTypeVideo) {
        CGAffineTransform t = asset.transform;
        
        
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0)
        {
            sR = YES;
            angleOrign = M_PI_2;
        }
        if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0)
        {
            sR = YES;
            angleOrign = -M_PI_2;
        }
        if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0)
        {
            sR = NO;
            angleOrign = 0;
        }
        if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0)
        {
            angleOrign = M_PI;
            sR = NO;
        }
        
    }
    
    if(sR){
        GLfloat quadTextureData1 [] = { //纹理坐标
            y,   x+w,
            y+h, x+w,
            y,   x,
            y+h, x,
        };
        
        memcpy(textureData, quadTextureData1, sizeof(quadTextureData1));
    }else{
        GLfloat quadTextureData1 [] = { //纹理坐标
            x,   y+h,
            x+w, y+h,
            x,   y,
            x+w, y,
        };
        
        memcpy(textureData, quadTextureData1, sizeof(quadTextureData1));
    }
    
    
    CGFloat dW = destinationSize.width*asset.rectInVideo.size.width;
    CGFloat dH = destinationSize.height*asset.rectInVideo.size.height;
    
    CGFloat sW,sH;
    if (sR) {
        sH  = sourceSize.width;
        sW  = sourceSize.height;
    }else{
        sW  = sourceSize.width;
        sH  = sourceSize.height;
    }
    sW *= w;
    sH *= h;
    float daspect = dW/dH;
    float saspect = sW/sH;
    float aspect = daspect/saspect;
    
    
    float scale  = 1.0;// = sinf(oangle)/sinf(oangle + angle);
    float scaleInv = 1.0;
    
    if (aspect < 1.0 && sR == NO) {
        // 水平
        float alpha = atanf(1.0/daspect);
        float beta = atanf(1.0/saspect);
        
        float angleNow = angle;
        if (angleNow >= M_PI) {
            angleNow -= M_PI;
        }
        if (angleNow > 0 && angleNow < alpha - beta) {
            scale = cosf(beta)/cosf(beta+angleNow);
        }
        
        if (angleNow >= alpha - beta && angleNow < M_PI - beta - alpha ) {
            angleNow -= (alpha -beta);
            scale = sinf(alpha)*cosf(beta)/cosf(alpha)/sinf(alpha+angleNow);
        }
        
        if (angleNow >= M_PI -beta -alpha && angleNow <= M_PI) {
            angleNow -= (M_PI - beta - alpha);
            scale = cosf(beta)/cosf(alpha-angleNow);
        }
        
        
        
        
    }else{
        // 左上右下对角线适配
        float alpha = atanf(1.0/daspect);
        float beta = atanf(1.0/saspect);
        
        float angleNow = angle;
        if (angleNow >= M_PI) {
            angleNow -= M_PI;
        }
        if (angleNow >= 0 && angleNow < M_PI - alpha - beta) {
            scale = sinf(beta)/sinf(beta+angleNow);
        }
        
        if (angleNow >= M_PI - alpha - beta && angleNow < M_PI - beta + alpha ) {
            angleNow -= (M_PI - alpha -beta);
            scale = cosf(alpha)*sinf(beta)/sinf(alpha)/cosf(alpha-angleNow);
        }
        
        if (angleNow >= M_PI -beta +alpha && angleNow <= M_PI) {
            angleNow -= (M_PI - beta + alpha);
            scale = sinf(beta)/sinf(alpha+angleNow);
        }
        
    }
    
    
    if (aspect < 1.0 && sR == NO) {
        // 水平
        
        // 水平
        float alpha = atanf(1.0/daspect);
        float beta = atanf(1.0/saspect);
        
        float angleNow = angle;
        if (angleNow >= M_PI) {
            angleNow -= M_PI;
        }
        
        
        if (angleNow > 0 && angleNow < alpha + beta) {
            scaleInv = cosf(beta)/cosf(beta - angleNow);
        }
        
        if (angleNow >= alpha + beta && angleNow < M_PI + beta - alpha ) {
            angleNow -= (alpha + beta);
            scaleInv = sinf(alpha)*cosf(beta)/cosf(alpha)/sinf(alpha+angleNow);
        }
        
        if (angleNow >= M_PI +beta -alpha && angleNow <= M_PI) {
            angleNow -= (M_PI + beta - alpha);
            scaleInv = cosf(beta)/cosf(alpha-angleNow);
        }
        
        
    }else{
        // 右上左下对角线适配
        float alpha = atanf(1.0/daspect);
        float beta = atanf(1.0/saspect);
        float angleNow = angle;
        
        if (angleNow >= M_PI) {
            angleNow -= M_PI;
        }
        if (angleNow > 0 && angleNow < beta - alpha) {
            scaleInv = sinf(beta)/sinf(beta-angleNow);
        }
        
        if (angleNow >= beta - alpha && angleNow < beta+alpha ) {
            angleNow -= (beta - alpha);
            scaleInv = cosf(alpha)*sinf(beta)/sinf(alpha)/sinf(M_PI_2 + angleNow - alpha);
        }
        
        if (angleNow >= beta +alpha && angleNow <= M_PI) {
            angleNow -= (beta + alpha);
            scaleInv = sinf(beta)/sinf(alpha+angleNow);
        }
        
    }
    
    
    BOOL inve = YES;
    
    
    if (angle > 0.0 && angle < M_PI_2) {
        inve = YES;
    }
    if (angle >= M_PI_2 && angle < M_PI) {
        inve = NO;
    }
    if (angle > M_PI && angle <= M_PI_2*3) {
        inve = YES;
    }
    if (angle>M_PI_2*3 && angle <= M_PI*2) {
        inve = NO;
    }
    
    
    
    
    
    scale = MIN(scale, scaleInv);
    
    
    
    CGAffineTransform transform = CGAffineTransformRotate(CGAffineTransformIdentity, angleOrign);
    
    if (aspect<1.0) {
        
        if (sR) {
            transform =  CGAffineTransformScale(transform, 1.0, 1.0/aspect);//竖直
        }else{
            transform = CGAffineTransformScale(transform, 1.0,aspect);//水平
        }
        
        
    }else{
        if (sR) {
            transform =  CGAffineTransformScale(transform, 1.0, 1.0/aspect);//竖直
            
        }else{
            transform = CGAffineTransformScale(transform, 1.0/aspect, 1.0);//竖直
        }
        
    }
    
    
    //            float angle = M_PI_4;
    
    transform = CGAffineTransformScale(transform, 1.0, sR?1.0/saspect:saspect);
    transform = CGAffineTransformRotate(transform, angle);
    transform = CGAffineTransformScale(transform, 1.0, sR?saspect:1.0/saspect);
    
    
    if (!inve) {
        transform = CGAffineTransformScale(transform, scale*(asset.isVerticalMirror?-1:1), scale*(asset.isHorizontalMirror?-1:1));
    }else{
        transform = CGAffineTransformScale(transform, scale*(asset.isHorizontalMirror?-1:1), scale*(asset.isVerticalMirror?-1:1));
        
    }
    
    
    
    if (!sR) {
        transform = CGAffineTransformScale(transform, asset.rectInVideo.size.width, asset.rectInVideo.size.height);
    }else{
        transform = CGAffineTransformScale(transform, asset.rectInVideo.size.height, asset.rectInVideo.size.width);
        
    }
    
    
    return transform;
}
static Float64 factorForTimeInRange(CMTime time, CMTimeRange range) /* 0.0 -> 1.0 */
{
    
    CMTime elapsed = CMTimeSubtract(time, range.start);
    return CMTimeGetSeconds(elapsed) / CMTimeGetSeconds(range.duration);
}
///渲染主函数  渲染图片与视频  有优化的余地
#if 0

- (void) createDataFBO{
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    
    
    
}
- (void) createData{
    
    CFDictionaryRef empty; // empty value for attr value.
    CFMutableDictionaryRef attrs;
    empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    
    CVReturn err = CVPixelBufferCreate(kCFAllocatorDefault, (int)_videoSize.width, (int)_videoSize.height, kCVPixelFormatType_32BGRA, attrs, &renderTarget);
    if (err)
    {
        NSLog(@"FBO size: %f, %f", _videoSize.width, _videoSize.height);
        NSAssert(NO, @"Error at CVPixelBufferCreate %d", err);
    }
    CFRelease(attrs);
    CFRelease(empty);
    
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       [self videoTextureCache],
                                                       renderTarget,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RGBA,
                                                       (int)_videoSize.width,
                                                       (int)_videoSize.height,
                                                       GL_BGRA,
                                                       GL_UNSIGNED_BYTE,
                                                       0,
                                                       &renderTexture);
    if (err)
    {
        NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    
    
    glBindTexture(CVOpenGLESTextureGetTarget(renderTexture), CVOpenGLESTextureGetName(renderTexture));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(renderTexture), 0);
    
    
    __unused GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
    
}
- (void) setFilterFBO{
    if (!framebuffer) {
        [self createDataFBO];
    }
    //    [self createData];
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glViewport(0, 0, (int)_videoSize.width, (int)_videoSize.height);
    
    
    
}
#endif

- (void)renderCustomPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer scene:(XLScene *)scene request:(AVAsynchronousVideoCompositionRequest *)request
{
    float tweenFactor = factorForTimeInRange(request.compositionTime, scene.fixedTimeRange);
    
    [EAGLContext setCurrentContext:self.currentContext];
    
    
    glUseProgram(self.program);
    
    CVOpenGLESTextureRef destTexture = [self customTextureForPixelBuffer:destinationPixelBuffer];
    glBindFramebuffer(GL_FRAMEBUFFER, self.offscreenBufferHandle);
    glViewport(0, 0, (int)CVPixelBufferGetWidth(destinationPixelBuffer), (int)CVPixelBufferGetHeight(destinationPixelBuffer));
    
    
    
    // Attach the destination texture as a color attachment to the off screen frame buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(destTexture), 0);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        goto bail1;
    }
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    {
        
        
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        CGSize destinationSize = _videoSize;
        
        for(int i = 0;i<scene.vvAsset.count;i++){
            
            XLAsset* asset = scene.vvAsset[i];
            if(asset.type == XLAssetTypeVideo ) {
                CVPixelBufferRef sourcePixelBuffer = [request sourceFrameByTrackID:[asset.trackID intValue]];
                
                
                if (!sourcePixelBuffer) {
                    continue;
                }//在切换时有一帧读不出来。。。。
                
                CVOpenGLESTextureRef sourceTexture = [self customTextureForPixelBuffer:sourcePixelBuffer];
                
                
                glActiveTexture(GL_TEXTURE0);
                glBindTexture(GL_TEXTURE_2D, CVOpenGLESTextureGetName(sourceTexture));
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
                
                
                if (asset.maskURL) {
                    XLTexture* imageBuffer3 = [XLTexturePool.sharedInstance fetchImageTextureForPath:asset.maskURL];
                    glActiveTexture(GL_TEXTURE2);
                    glBindTexture(GL_TEXTURE_2D, imageBuffer3.texture);
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
                    
                    glUniform1i(normalInputTextureUniform2, 2);
                }
                
                GLfloat quadTextureData1[8] = {0};
                
                
                CGSize sourceSize = CGSizeMake(CVPixelBufferGetWidth(sourcePixelBuffer), CVPixelBufferGetHeight(sourcePixelBuffer));
                
                CGAffineTransform transform = [self transformFromAsset:asset sourceSize:sourceSize destinationSize:destinationSize textureData:quadTextureData1];
                
                GLfloat preferredRenderTransform [] = {
                    static_cast<GLfloat>(transform.a), static_cast<GLfloat>(transform.b), static_cast<GLfloat>(transform.tx), 0.0,
                    static_cast<GLfloat>(transform.c), static_cast<GLfloat>(transform.d), static_cast<GLfloat>(transform.ty), 0.0,
                    0.0,                       0.0,                                        1.0, 0.0,
                    0.0,                       0.0,                                        0.0, 1.0,
                };
                ksMatrixLoadIdentity(&_modelViewMatrix);
                ksMatrixInitFromArray(&_modelViewMatrix, preferredRenderTransform);
                
                glUniformMatrix4fv(normalTransformUniform, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
                
                ksMatrixLoadIdentity(&_projectionMatrix);
                
                
                float transX = (asset.rectInVideo.origin.x + asset.rectInVideo.size.width/2.0) - 0.5;
                float transY = (asset.rectInVideo.origin.y + asset.rectInVideo.size.height/2.0) - 0.5;
                
                float size = 2.0; //不知道为什么？
                ksMatrixTranslate(&_projectionMatrix,transX*size , transY*size, 0);
                
                glUniformMatrix4fv(normalProjectionUniform, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
                
                
                glUniform1i(normalInputTextureUniform, 0);
                glUniform4f(normalColorUniform, 1.0, 1.0, 1.0, tweenFactor);
                
                //外部传入四个点 决定一个矩形，按照此矩形crop
                //依据这个矩形算出vertex 依据vertex映射texture
                
                GLfloat quadVertexData1 [] = {
                    -1.0, 1.0,
                    1.0, 1.0,
                    -1.0, -1.0,
                    1.0, -1.0,
                };
                
                
                glVertexAttribPointer(normalPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData1);
                glEnableVertexAttribArray(normalPositionAttribute);
                
                glVertexAttribPointer(normalTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData1);
                
                
                glEnableVertexAttribArray(normalTextureCoordinateAttribute);
                glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
                
                CFRelease(sourceTexture);
                
            }
            
            if (asset.type == XLAssetTypeImage && asset.last <= tweenFactor) {
                XLTexture* imageBuffer;
                
                
                float value = 1.0;
                
                
                
                if (asset.type == XLAssetTypeImage) {
                    imageBuffer = [XLTexturePool.sharedInstance fetchImageTextureForPath:asset.url];
                    
                }
                
                if (asset.fillType == XLImageFillTypeFit) {
                    value = 1.0;
                }
                
                if (asset.fillType == XLImageFillTypeFitZoomOut) {
                    value = 1.2 - 0.2 * tweenFactor;
                }
                
                if (asset.fillType == XLImageFillTypeFitZoomIn) {
                    value = 0.8 + 0.2 * tweenFactor;
                }
                if (asset.maskURL) {
                    XLTexture* imageBuffer3 = [XLTexturePool.sharedInstance fetchImageTextureForPath:asset.maskURL];
                    glActiveTexture(GL_TEXTURE2);
                    glBindTexture(GL_TEXTURE_2D, imageBuffer3.texture);
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
                    
                    glUniform1i(normalInputTextureUniform2, 2);
                }
                glActiveTexture(GL_TEXTURE0);
                glBindTexture(GL_TEXTURE_2D, imageBuffer.texture);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
                
                // 需要设置asset的size
                GLfloat quadTextureData1[8] = {0};
                
                CGSize sourceSize = CGSizeMake(imageBuffer.width, imageBuffer.height);
                
                CGAffineTransform transform = [self transformFromAsset:asset sourceSize:sourceSize destinationSize:destinationSize textureData:quadTextureData1];
                
                
                
                transform = CGAffineTransformScale(transform, value, value);
                
                GLfloat preferredRenderTransform [] = {
                    static_cast<GLfloat>(transform.a), static_cast<GLfloat>(transform.b), static_cast<GLfloat>(transform.tx), 0.0,
                    static_cast<GLfloat>(transform.c), static_cast<GLfloat>(transform.d), static_cast<GLfloat>(transform.ty), 0.0,
                    0.0,                       0.0,                                        1.0, 0.0,
                    0.0,                       0.0,                                        0.0, 1.0,
                };
                
                ksMatrixLoadIdentity(&_modelViewMatrix);
                
                if (asset.fillType != XLImageFillTypeFull) {
                    ksMatrixInitFromArray(&_modelViewMatrix, preferredRenderTransform);
                }
                
                glUniformMatrix4fv(normalTransformUniform, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
                
                
                ksMatrixLoadIdentity(&_projectionMatrix);
                
                if (asset.fillType != XLImageFillTypeFull) {
                    
                    float transX = (asset.rectInVideo.origin.x + asset.rectInVideo.size.width/2.0) - 0.5;
                    float transY = (asset.rectInVideo.origin.y + asset.rectInVideo.size.height/2.0) - 0.5;
                    
                    float size = 2.0;//如何确定这个值？
                    
                    
                    ksMatrixTranslate(&_projectionMatrix,transX*size , transY*size, 0);
                    
                }
                
                
                glUniformMatrix4fv(normalProjectionUniform, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
                
                
                
                glUniform1i(normalInputTextureUniform, 0);
                glUniform4f(normalColorUniform, 1.0, 1.0, 1.0, tweenFactor);
                GLfloat quadVertexData1 [] = {
                    -1.0, 1.0,
                    1.0, 1.0,
                    -1.0, -1.0,
                    1.0, -1.0,
                };
                
                glVertexAttribPointer(normalPositionAttribute, 2, GL_FLOAT, 0, 0, quadVertexData1);
                glEnableVertexAttribArray(normalPositionAttribute);
                
                
                glVertexAttribPointer(normalTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData1);
                
                
                glEnableVertexAttribArray(normalTextureCoordinateAttribute);
                
                glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
                
                
            }
            
        }
        glFlush();
    }
    
    
bail1:
    CFRelease(destTexture);
    
    // Periodic texture cache flush every frame
    //    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
    //
    [EAGLContext setCurrentContext:nil];
    
}

- (void) particleRenderPixeBuffer:(CVPixelBufferRef) destinationPixelBuffer
                 usingSouceBuffer:(CVPixelBufferRef) sourcePixelBuffer

{
    [EAGLContext setCurrentContext:self.currentContext];
    
    
    
    CVOpenGLESTextureRef destTexture = [self customTextureForPixelBuffer:destinationPixelBuffer];
    glBindFramebuffer(GL_FRAMEBUFFER, self.offscreenBufferHandle);
    glViewport(0, 0, (int)CVPixelBufferGetWidth(destinationPixelBuffer), (int)CVPixelBufferGetHeight(destinationPixelBuffer));
    
    
    
    // Attach the destination texture as a color attachment to the off screen frame buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(destTexture), 0);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        goto bailMask;
    }
    
    
    
    
    
    {
        
        glUseProgram(self.particleProgram);
        
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
        
        
        
        //        glUniform4f(particleColorUniform, 1.0, 1.0, 1.0, 1.0);
        
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
        
        //        RenderUnit unit = units[0];
        
        for(auto unit : units){
            
            vertexData->positions.resize(unit.nPositionCount);
            vertexData->indices.resize(unit.nIndexCount);
            vertexData->texcoords.resize(unit.nPositionCount);
            vertexData->colors.resize(unit.nPositionCount);
            
            Matrix4 ortho = Matrix4::ortho(0, _videoSize.width, _videoSize.height, 0, -1, 1);
            Matrix4 tranform = Matrix4::makeTransform(Vec3(0, _videoSize.height, 0), Vec3(1, -1, 1));
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
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            
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
    
bailMask:
    CFRelease(destTexture);
    
    // Periodic texture cache flush every frame
    //    CVOpenGLESTextureCacheFlush(self.videoTextureCache, 0);
    //
    [EAGLContext setCurrentContext:nil];
}



- (void) renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer
usingForegroundSourceBuffer:(CVPixelBufferRef)foregroundPixelBuffer
 andBackgroundSourceBuffer:(CVPixelBufferRef)backgroundPixelBuffer
          andMaskImagePath:(NSURL *) path
            forTweenFactor:(float)tween
{
    [EAGLContext setCurrentContext:self.currentContext];
    
    
    glUseProgram(self.maskProgram);
    
    CVOpenGLESTextureRef destTexture = [self customTextureForPixelBuffer:destinationPixelBuffer];
    glBindFramebuffer(GL_FRAMEBUFFER, self.offscreenBufferHandle);
    glViewport(0, 0, (int)CVPixelBufferGetWidth(destinationPixelBuffer), (int)CVPixelBufferGetHeight(destinationPixelBuffer));
    
    
    
    // Attach the destination texture as a color attachment to the off screen frame buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(destTexture), 0);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        goto bailMask;
    }
    
    
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
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        
        
        
        glUseProgram(self.maskProgram);
        
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
    
bailMask:
    CFRelease(destTexture);
    
    // Periodic texture cache flush every frame
    //    CVOpenGLESTextureCacheFlush(self.videoTextureCache, 0);
    //
    [EAGLContext setCurrentContext:nil];
    
}



- (void)renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer usingForegroundSourceBuffer:(CVPixelBufferRef)foregroundPixelBuffer andBackgroundSourceBuffer:(CVPixelBufferRef)backgroundPixelBuffer forTweenFactor:(float)tween type:(unsigned int) type
{
    [EAGLContext setCurrentContext:self.currentContext];
    
    CVOpenGLESTextureRef destTexture = [self customTextureForPixelBuffer:destinationPixelBuffer];
    glBindFramebuffer(GL_FRAMEBUFFER, self.offscreenBufferHandle);
    glViewport(0, 0, (int)CVPixelBufferGetWidth(destinationPixelBuffer), (int)CVPixelBufferGetHeight(destinationPixelBuffer));
    CVOpenGLESTextureRef foregroundTexture = [self customTextureForPixelBuffer:foregroundPixelBuffer];
    
    CVOpenGLESTextureRef backgroundTexture = [self customTextureForPixelBuffer:backgroundPixelBuffer];
    
    
    // Attach the destination texture as a color attachment to the off screen frame buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(destTexture), 0);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        goto bail2;
    }
    
    
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
            glUseProgram(self.program);
            //            [program use];
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
        if (transitionType == 5 || transitionType == 6 || transitionType == 7 ) { // 淡入
            glUseProgram(self.blendProgram);
            
            
            
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
    
bail2:
    CFRelease(foregroundTexture);
    CFRelease(backgroundTexture);
    CFRelease(destTexture);
    // Periodic texture cache flush every frame
    //    CVOpenGLESTextureCacheFlush(self.videoTextureCache, 0);
    //
    [EAGLContext setCurrentContext:nil];
    
    
    
    
}

- (void)setupOffscreenRenderContext
{
    //-- Create CVOpenGLESTextureCacheRef for optimal CVPixelBufferRef to GLES texture conversion.
    if (_videoTextureCache) {
        CFRelease(_videoTextureCache);
        _videoTextureCache = NULL;
    }
    
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _currentContext, NULL, &_videoTextureCache);
    if (err != noErr) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
    }
    
    glDisable(GL_DEPTH_TEST);
    
    
    glGenFramebuffers(1, &_offscreenBufferHandle);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _offscreenBufferHandle);
    
    
    
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    
    _program          = glCreateProgram();
    _blendProgram     = glCreateProgram();
    _maskProgram      = glCreateProgram();
    
    _particleProgram = glCreateProgram();
    
    
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER source:kRDCompositorVertexShader]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER source:kRDCompositorFragmentShader]) {
        NSLog(@"Failed to compile cust fragment shader");
        return NO;
    }
    
    if (![self compileShader:&blendFragShader type:GL_FRAGMENT_SHADER source:kRDCompositorBlendFragmentShader]) {
        NSLog(@"Failed to compile blend fragment shader");
        return NO;
    }
    
    if (![self compileShader:&maskFragShader type:GL_FRAGMENT_SHADER source:kRDCompositorPassThroughMaskFragmentShader]) {
        NSLog(@"Failed to compile mask fragment shader");
        return NO;
    }
    
    if (![self compileShader:&particleVertShader type:GL_VERTEX_SHADER source:kRDParticleVertexShader]) {
        
    }
    if (![self compileShader:&particleFragShader type:GL_FRAGMENT_SHADER source:kRDParticleFragmentShader]) {
        
    }
    
    
    
    glReleaseShaderCompiler();
    
    glAttachShader(_program, vertShader);
    glAttachShader(_program, fragShader);
    
    glAttachShader(_blendProgram, vertShader);
    glAttachShader(_blendProgram, blendFragShader);
    
    glAttachShader(_maskProgram, vertShader);
    glAttachShader(_maskProgram, maskFragShader);
    
    glAttachShader(_particleProgram, particleVertShader);
    glAttachShader(_particleProgram, particleFragShader);
    
    // Link the program.
    if (![self linkProgram:_program]           ||
        ![self linkProgram:_blendProgram]      ||
        ![self linkProgram:_maskProgram]       ||
        ![self linkProgram:_particleProgram]
        ) {
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        
        if (blendFragShader) {
            glDeleteShader(blendFragShader);
            blendFragShader = 0;
        }
        if (maskFragShader) {
            glDeleteShader(maskFragShader);
            maskFragShader = 0;
        }
        if (particleVertShader) {
            glDeleteShader(particleVertShader);
            particleVertShader = 0;
        }
        if (particleFragShader) {
            glDeleteShader(particleFragShader);
            particleFragShader = 0;
        }
        
        
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        if (_blendProgram) {
            glDeleteProgram(_blendProgram);
            _blendProgram = 0;
        }
        
        if (_maskProgram) {
            glDeleteProgram(_maskProgram);
            _maskProgram = 0;
        }
        if (_particleProgram) {
            glDeleteProgram(_particleProgram);
            _particleProgram = 0;
        }
        
        return NO;
    }
    
    
    
    // Get uniform locations.
    
    normalPositionAttribute = glGetAttribLocation(_program, "position");
    normalTextureCoordinateAttribute = glGetAttribLocation(_program, "inputTextureCoordinate");
    normalProjectionUniform = glGetUniformLocation(_program, "projection");
    normalInputTextureUniform = glGetUniformLocation(_program, "inputImageTexture");
    normalInputTextureUniform2 = glGetUniformLocation(_program, "inputImageTexture2");
    normalTransformUniform = glGetUniformLocation(_program, "renderTransform");
    normalColorUniform = glGetUniformLocation(_program, "color");
    
    
    
    blendPositionAttribute = glGetAttribLocation(_blendProgram, "position");
    blendTextureCoordinateAttribute = glGetAttribLocation(_blendProgram, "inputTextureCoordinate");
    blendProjectionUniform = glGetUniformLocation(_blendProgram, "projection");
    blendInputTextureUniform = glGetUniformLocation(_blendProgram, "inputImageTexture");
    blendInputTextureUniform2 = glGetUniformLocation(_blendProgram, "inputImageTexture2");
    blendTransformUniform = glGetUniformLocation(_blendProgram, "renderTransform");
    blendColorUniform = glGetUniformLocation(_blendProgram, "color");
    blendFactorUniform = glGetUniformLocation(_blendProgram, "factor");
    blendBrightnessUniform = glGetUniformLocation(_blendProgram, "brightness");
    
    
    
    maskPositionAttribute = glGetAttribLocation(_maskProgram, "position");
    maskTextureCoordinateAttribute = glGetAttribLocation(_maskProgram, "inputTextureCoordinate");
    maskProjectionUniform = glGetUniformLocation(_maskProgram, "projection");
    maskInputTextureUniform = glGetUniformLocation(_maskProgram, "inputImageTexture");
    maskInputTextureUniform2 = glGetUniformLocation(_maskProgram, "inputImageTexture2");
    maskInputTextureUniform3 = glGetUniformLocation(_maskProgram, "inputImageTexture3");
    maskTransformUniform = glGetUniformLocation(_maskProgram, "renderTransform");
    maskFactorUniform = glGetUniformLocation(_maskProgram, "factor");
    
    
    particlePositionAttribute = glGetAttribLocation(_particleProgram, "position");
    particleTextureCoordinateAttribute = glGetAttribLocation(_particleProgram, "inputTextureCoordinate");
    particleTextureColorAttribute = glGetAttribLocation(_particleProgram, "inputTextureColor");
    particleInputTextureUniform = glGetUniformLocation(_particleProgram, "inputImageTexture");
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    if (blendFragShader) {
        glDetachShader(_blendProgram, blendFragShader);
        glDeleteShader(blendFragShader);
    }
    if (maskFragShader) {
        glDetachShader(_maskProgram, maskFragShader);
        glDeleteShader(maskFragShader);
    }
    if (particleVertShader) {
        glDetachShader(_particleProgram, particleVertShader);
        glDeleteShader(particleVertShader);
    }
    if (particleFragShader) {
        glDetachShader(_particleProgram, particleFragShader);
        glDeleteShader(particleFragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type source:(NSString *)sourceString
{
    if (sourceString == nil) {
        NSLog(@"Failed to load vertex shader: Empty source string");
        return NO;
    }
    
    GLint status;
    const GLchar *source;
    source = (GLchar *)[sourceString UTF8String];
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

#if defined(DEBUG)

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

#endif

#pragma mark -- Get TextureRef from PixelBuffer
- (CVOpenGLESTextureRef)lumaTextureForPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    CVOpenGLESTextureRef lumaTexture = NULL;
    CVReturn err;
    
    if (!_videoTextureCache) {
        NSLog(@"No video texture cache");
        goto bail;
    }
    
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
    
    // CVOpenGLTextureCacheCreateTextureFromImage will create GL texture optimally from CVPixelBufferRef.
    // Y
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       _videoTextureCache,
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
    
    if (!_videoTextureCache) {
        NSLog(@"No video texture cache");
        goto bail;
    }
    
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
    
    // CVOpenGLTextureCacheCreateTextureFromImage will create GL texture optimally from CVPixelBufferRef.
    // UV
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       _videoTextureCache,
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
    
    if (!_videoTextureCache) {
        NSLog(@"No video texture cache");
        goto bail;
    }
    {
        int width = (int)CVPixelBufferGetWidth(pixelBuffer);
        int height = (int)CVPixelBufferGetHeight(pixelBuffer);
        
        CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
        
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           _videoTextureCache,
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
- (CVOpenGLESTextureRef)customTextureForPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    CVOpenGLESTextureRef bgraTexture = NULL;
    CVReturn err;
    //
    //    if (!_videoTextureCache) {
    //        NSLog(@"No video texture cache");
    //        goto bail;
    //    }
    //
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
    
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       [self videoTextureCache],
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

@end

