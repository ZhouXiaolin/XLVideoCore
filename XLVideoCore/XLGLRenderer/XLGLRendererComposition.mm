//
//  XLVideoCompositorRenderer.m
//  XLVideoCore
//
//  Created by 周晓林 on 2018/5/28.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#import "XLGLRendererComposition.h"


#import "XLGLRendererMain.h"
#import "XLGLRendererTransitionMask.h"
#import "XLGLRendererTransitionSimple.h"
#import "XLGLRendererTransitionBlend.h"
#import "XLGLRendererParticle.h"


@interface XLGLRendererComposition ()
{
    
    XLGLRendererMain* mainRenderer;
    XLGLRendererTransitionMask* maskTransitionRenderer;
    XLGLRendererTransitionBlend* blendTransitionRenderer;
    XLGLRendererTransitionSimple* simpleTransitionRenderer;
    XLGLRendererParticle* particleRenderer;
    
}
@end

@implementation XLGLRendererComposition

+ (XLGLRendererComposition *)sharedVideoCompositorRender{
    static XLGLRendererComposition* renderer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        renderer = [[[self class] alloc] init];
        NSLog(@"%s",__func__);
    });
    return renderer;
}


- (void) clear
{
    [XLTexturePool.sharedInstance clear];    
}
- (void)dealloc
{
    NSLog(@"%s",__func__);
    

}


- (void)renderCustomPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer scene:(XLScene *)scene request:(AVAsynchronousVideoCompositionRequest *)request{
    
    if (!mainRenderer) {
        mainRenderer = [[XLGLRendererMain alloc] init];
        mainRenderer.videoSize = _videoSize;
    }
    [mainRenderer renderCustomPixelBuffer:destinationPixelBuffer scene:scene request:request];
    
}


- (void) particleRenderPixeBuffer:(CVPixelBufferRef) destinationPixelBuffer
                 usingSouceBuffer:(CVPixelBufferRef) sourcePixelBuffer

{
    if (!particleRenderer) {
        particleRenderer = [[XLGLRendererParticle alloc] init];
        particleRenderer.videoSize = _videoSize;
    }
    [particleRenderer particleRenderPixeBuffer:destinationPixelBuffer usingSouceBuffer:sourcePixelBuffer];

}


- (void) renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer
usingForegroundSourceBuffer:(CVPixelBufferRef)foregroundPixelBuffer
 andBackgroundSourceBuffer:(CVPixelBufferRef)backgroundPixelBuffer
          andMaskImagePath:(NSURL *) path
            forTweenFactor:(float)tween
{

    if (!maskTransitionRenderer) {
        maskTransitionRenderer = [[XLGLRendererTransitionMask alloc] init];
        maskTransitionRenderer.videoSize = _videoSize;
    }
    
    [maskTransitionRenderer renderPixelBuffer:destinationPixelBuffer usingForegroundSourceBuffer:foregroundPixelBuffer andBackgroundSourceBuffer:backgroundPixelBuffer andMaskImagePath:path forTweenFactor:tween];
    
}



- (void)renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer usingForegroundSourceBuffer:(CVPixelBufferRef)foregroundPixelBuffer andBackgroundSourceBuffer:(CVPixelBufferRef)backgroundPixelBuffer forTweenFactor:(float)tween type:(unsigned int) type
{
        int transitionType = type;
        if (transitionType <= 4) {

            if (!simpleTransitionRenderer) {
                simpleTransitionRenderer = [[XLGLRendererTransitionSimple alloc] init];
                simpleTransitionRenderer.videoSize = _videoSize;
            }
            [simpleTransitionRenderer renderPixelBuffer:destinationPixelBuffer usingForegroundSourceBuffer:foregroundPixelBuffer andBackgroundSourceBuffer:backgroundPixelBuffer forTweenFactor:tween type:type];
            
        }
        if (transitionType == 5 || transitionType == 6 || transitionType == 7 ) { // 淡入

            if (!blendTransitionRenderer) {
                blendTransitionRenderer = [[XLGLRendererTransitionBlend alloc] init];
                blendTransitionRenderer.videoSize = _videoSize;
            }
            [blendTransitionRenderer renderPixelBuffer:destinationPixelBuffer usingForegroundSourceBuffer:foregroundPixelBuffer andBackgroundSourceBuffer:backgroundPixelBuffer forTweenFactor:tween type:type];
           
            
        }
    
}



@end

