//
//  XLTexturePool.h
//  XLVideoCore
//
//  Created by 周晓林 on 2018/5/28.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface XLTexture : NSObject
@property (readonly) GLuint texture;
@property (readonly) float width;
@property (readonly) float height;
- (void) loadImagePath:(NSURL *)path;
- (void) clear;
@end


@interface XLTexturePool : NSObject
+ (XLTexturePool *) sharedInstance;
- (XLTexture *) fetchImageTextureForPath:(NSURL *)url;
- (void) clear;
@end
