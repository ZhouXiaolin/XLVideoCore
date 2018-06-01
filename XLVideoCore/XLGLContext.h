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
#import "XLGLProgram.h"
@interface XLGLContext : NSObject
@property (readonly, retain, nonatomic) EAGLContext* context;
@property (readonly) CVOpenGLESTextureCacheRef coreVideoTextureCache;
+ (XLGLContext *) context;
+ (void) useContext;
- (void) useAsCurrentContext;
@end
