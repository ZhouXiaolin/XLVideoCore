//
//  XLVideoCompositorContext.h
//  XLVideoCore
//
//  Created by 周晓林 on 2018/5/31.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <OpenGLES/EAGL.h>
@interface XLVideoCompositorContext : NSObject
@property (readonly, retain, nonatomic) EAGLContext* context;
@property (readonly) CVOpenGLESTextureCacheRef coreVideoTextureCache;
- (void) useAsCurrentContext;
@end
