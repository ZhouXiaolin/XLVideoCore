//
//  XLVideoCompositor.m
//  XLVideoCore
//
//  Created by 周晓林 on 2018/5/28.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#import "XLVideoCompositor.h"
#import "XLVideoCompositorRenderer.h"
#import "XLVideoCompositorInstruction.h"
#import "XLScene.h"
#define RENDERINGQUEUE "com.17rd.xpk.renderingqueue"
#define RENDERCONTEXTQUEUE "com.17rd.xpk.rendercontextqueue"
#import <UIKit/UIKit.h>
@interface XLVideoCompositor(){
    BOOL _shouldCancelAllRequest;
    BOOL _renderContextDidChange;
    dispatch_queue_t _renderingQueue;
    dispatch_queue_t _renderContextQueue;
    AVVideoCompositionRenderContext *_renderContext;
    
    XLVideoCompositorRenderer* _renderer;
    
    
    
}
@end
@implementation XLVideoCompositor
- (instancetype)init{
    if (self = [super init]) {
        _renderingQueue = dispatch_queue_create(RENDERINGQUEUE, DISPATCH_QUEUE_SERIAL);
        _renderContextQueue = dispatch_queue_create(RENDERCONTEXTQUEUE, DISPATCH_QUEUE_SERIAL);
        _renderContextDidChange = NO;
        _renderer = [[XLVideoCompositorRenderer alloc] init];//多次初始化videocore会崩溃
        
        
        
        
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
    return @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],
              (NSString*)kCVPixelBufferOpenGLESCompatibilityKey : [NSNumber numberWithBool:YES]};
}

- (NSDictionary *)requiredPixelBufferAttributesForRenderContext
{
    return @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],
              (NSString*)kCVPixelBufferOpenGLESCompatibilityKey : [NSNumber numberWithBool:YES]};
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
    
    
    _renderer.videoSize = renderSize;
    
    XLVideoCompositorInstruction* instruction = request.videoCompositionInstruction;
    
    if (instruction.customType == XLCustomTypePassThrough) {
        XLScene* scene = instruction.scene;
        [_renderer renderCustomPixelBuffer:dstPixels scene:scene request:request];
        
    }
    
    
    if (instruction.customType == XLCustomTypeTransition) {
        
        CVPixelBufferRef previousPixels = [_renderContext newPixelBuffer];
        XLScene* previousScene = instruction.previosScene;
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
    
}


- (void)dealloc
{
    NSLog(@"%s",__func__);
}
- (void)cancelAllPendingVideoCompositionRequests{
    
}
@end
