//
//  XLGLMainRenderer.m
//  XLVideoCore
//
//  Created by 周晓林 on 2018/5/31.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#import "XLGLRendererMain.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "XLVideoCompositorInstruction.h"

@interface XLGLRendererMain()
{
    GLuint normalPositionAttribute,normalTextureCoordinateAttribute;
    GLuint normalInputTextureUniform,normalInputTextureUniform2;
    GLuint normalProjectionUniform,normalTransformUniform,normalColorUniform;
    
    
    ksMatrix4 _modelViewMatrix;
    ksMatrix4 _projectionMatrix;
    
    XLGLProgram* _program;
    
    XLGLFramebuffer* _framebuffer;

}
@end

@implementation XLGLRendererMain
- (instancetype)init{
    if (!(self = [super init])) {
        return nil;
    }

    [XLGLContext useContext];
    
    
    _framebuffer = [[XLGLFramebuffer alloc] init];
    
    [self loadShaders];
    
    
    return self;
}

Float64 factorForTimeInRange(CMTime time, CMTimeRange range)
{
    
    CMTime elapsed = CMTimeSubtract(time, range.start);
    return CMTimeGetSeconds(elapsed) / CMTimeGetSeconds(range.duration);
}


- (void)renderCustomPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer scene:(XLScene *)scene request:(AVAsynchronousVideoCompositionRequest *)request
{
    float tweenFactor = factorForTimeInRange(request.compositionTime, scene.fixedTimeRange);
    
    
    [XLGLContext useContext];

    [_program use];
    
    
    [_framebuffer render:destinationPixelBuffer];
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    {
        
        
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        CGSize destinationSize = self.videoSize;
        
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
                glUniform4f(normalColorUniform, 1.0, 1.0, 1.0, 1.0);
                
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
                    
                    glUniform1i(normalInputTextureUniform2, 2);
                }
                glActiveTexture(GL_TEXTURE0);
                glBindTexture(GL_TEXTURE_2D, imageBuffer.texture);
                
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
    
}

- (void) loadShaders {
    _program = [[XLGLProgram alloc] initWithVertexShaderString:kXLCompositorVertexShader fragmentShaderString:kXLCompositorFragmentShader];
    [_program link];
    
    
    normalPositionAttribute = [_program attributeIndex: @"position"];
    normalTextureCoordinateAttribute = [_program attributeIndex: @"inputTextureCoordinate"];
    normalProjectionUniform = [_program uniformIndex: @"projection"];
    normalInputTextureUniform = [_program uniformIndex: @"inputImageTexture"];
    normalInputTextureUniform2 = [_program uniformIndex: @"inputImageTexture2"];
    normalTransformUniform = [_program uniformIndex: @"renderTransform"];
    normalColorUniform = [_program uniformIndex: @"color"];
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
@end
