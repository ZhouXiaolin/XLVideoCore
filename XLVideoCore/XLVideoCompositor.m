//
//  XLVideoCompositor.m
//  XLVideoCore
//
//  Created by 周晓林 on 2018/5/28.
//  Copyright © 2018年 Solaren. All rights reserved.
//



#import "XLVideoCompositor.h"
#import "XLVideoCompositorInstruction.h"
#import "XLScene.h"


#define USE_OPENGL
//#define USE_METAL


#ifdef USE_OPENGL
#import "XLGLRendererComposition.h"
#else
#import "XLMTLRendererComposition.h"
#endif


#define RENDERINGQUEUE "com.mfasta.videocore.renderingqueue"
#define RENDERCONTEXTQUEUE "com.mfasta.videocore.rendercontextqueue"
#import <UIKit/UIKit.h>
@interface XLVideoCompositor(){
    BOOL _shouldCancelAllRequest;
    BOOL _renderContextDidChange;
    dispatch_queue_t _renderingQueue;
    dispatch_queue_t _renderContextQueue;
    AVVideoCompositionRenderContext *_renderContext;
#ifdef USE_OPENGL
    XLGLRendererComposition* _renderer;
#else
    XLMTLRendererComposition* _renderer;
#endif
    
    
}
@end
@implementation XLVideoCompositor
- (instancetype)init{
    if (self = [super init]) {
        _renderingQueue = dispatch_queue_create(RENDERINGQUEUE, DISPATCH_QUEUE_SERIAL);
        _renderContextQueue = dispatch_queue_create(RENDERCONTEXTQUEUE, DISPATCH_QUEUE_SERIAL);
        _renderContextDidChange = NO;
        
#ifdef USE_OPENGL
        _renderer = [[XLGLRendererComposition alloc] init];
#else
        _renderer = [[XLMTLRendererComposition alloc] init];
#endif
        
        
        
    }
    return self;
}


- (BOOL)supportsWideColorSourceFrames{
    return NO;
}

- (void)renderContextChanged:(AVVideoCompositionRenderContext *)newRenderContext{
    dispatch_sync(_renderContextQueue, ^{
        self->_renderContext = newRenderContext;
        self->_renderContextDidChange = YES;
    });
}
- (NSDictionary *)sourcePixelBufferAttributes
{
    
    
    return @{
             (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],
#ifdef USE_OPENGL
              (NSString*)kCVPixelBufferOpenGLESCompatibilityKey : [NSNumber numberWithBool:YES]
#else
             (NSString*)kCVPixelBufferMetalCompatibilityKey : [NSNumber numberWithBool:YES]
#endif
              
              };
}

- (NSDictionary *)requiredPixelBufferAttributesForRenderContext
{
    return @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],
#ifdef USE_OPENGL
              (NSString*)kCVPixelBufferOpenGLESCompatibilityKey : [NSNumber numberWithBool:YES]
#else
              (NSString*)kCVPixelBufferMetalCompatibilityKey : [NSNumber numberWithBool:YES]
#endif
              };
}

- (void)startVideoCompositionRequest:(AVAsynchronousVideoCompositionRequest *)request
{

    @autoreleasepool {
        dispatch_async(_renderingQueue, ^{            
            if (self->_shouldCancelAllRequest) {
                [request finishCancelledRequest];
            }else{
                
                
                
                NSError *err = nil;
                
                CVPixelBufferRef resultPixels = [self newRenderedPixelBufferForRequest:request error:&err];
                if (resultPixels) {
                    [request finishWithComposedVideoFrame:resultPixels];
                    CVPixelBufferRelease(resultPixels);
                    resultPixels = nil;
                    
                }else{
                    [request finishWithError:err];
                }
            }
        });
    }
    
}
static Float64 factorForTimeInRange(CMTime time, CMTimeRange range) /* 0.0 -> 1.0 */
{
    
    CMTime elapsed = CMTimeSubtract(time, range.start);
    return CMTimeGetSeconds(elapsed) / CMTimeGetSeconds(range.duration);
}
- (CVPixelBufferRef)newRenderedPixelBufferForRequest:(AVAsynchronousVideoCompositionRequest *)request error:(NSError **)errOut
{
    
    CVPixelBufferRef dstPixels = [_renderContext newPixelBuffer];
    CGSize renderSize = _renderContext.size;
    
    
#ifdef USE_OPENGL
    _renderer.videoSize = renderSize;
    XLVideoCompositorInstruction* instruction = request.videoCompositionInstruction;
    
    if (instruction.customType == XLCustomTypePassThrough) {
        XLScene* scene = instruction.scene;
        [_renderer renderCustomPixelBuffer:dstPixels scene:scene request:request];
        
    }
    
    
    if (instruction.customType == XLCustomTypeTransition) {
        
        CVPixelBufferRef previousPixels = [_renderContext newPixelBuffer];
        XLScene* previousScene = instruction.scene;
        [_renderer renderCustomPixelBuffer:previousPixels scene:previousScene request:request];
        
        CVPixelBufferRef nextPixels = [ _renderContext newPixelBuffer];
        XLScene* nextScene = instruction.nextScene;
        [_renderer renderCustomPixelBuffer:nextPixels scene:nextScene request:request];
        
        float tweenFactor = factorForTimeInRange(request.compositionTime, request.videoCompositionInstruction.timeRange);
        
        if (previousScene.transition.type == XLVideoTransitionTypeMask) {
            [_renderer renderPixelBuffer:dstPixels usingForegroundSourceBuffer:previousPixels andBackgroundSourceBuffer:nextPixels andMaskImagePath:previousScene.transition.maskURL forTweenFactor:tweenFactor];
        }else{
            [_renderer renderPixelBuffer:dstPixels usingForegroundSourceBuffer:previousPixels andBackgroundSourceBuffer:nextPixels forTweenFactor:tweenFactor type:previousScene.transition.type];
        }
        
        
        CVPixelBufferRelease(previousPixels);
        CVPixelBufferRelease(nextPixels);
    }
    
    

    
    
    /// 将粒子效果绘制到屏幕上
    
    
    return dstPixels;
#else
    
#endif
}


- (void)dealloc
{
    NSLog(@"%s",__func__);
}
- (void)cancelAllPendingVideoCompositionRequests{
    
}
@end
