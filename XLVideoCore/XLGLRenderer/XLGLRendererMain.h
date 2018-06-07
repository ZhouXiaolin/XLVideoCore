//
//  XLGLMainRenderer.h
//  XLVideoCore
//
//  Created by 周晓林 on 2018/5/31.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XLGLRendererBase.h"
// 主渲染 处理每一个场景的视频渲染

// OnInit()
// OnRunning()
// OnCleanup()


@interface XLGLRendererMain : XLGLRendererBase

- (void)renderCustomPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer
                          scene:(XLScene *)scene
                        request:(AVAsynchronousVideoCompositionRequest *)request;
@end
/*
 
 
 
 class XLAppMain {
 public:
 AppState::Code OnRunning();
 AppState::Code OnInit();
 AppState::Code OnCleanup();
 
 PassAction passAction;
 
 
 };
 
 
 
 
 
 
 
 
 
 
*/
