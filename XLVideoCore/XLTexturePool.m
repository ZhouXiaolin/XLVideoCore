//
//  XLTexturePool.m
//  XLVideoCore
//
//  Created by 周晓林 on 2018/5/28.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#import "XLTexturePool.h"

#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@interface XLTexture()
{
    GLuint _imageTexture;
    float imageWidth;
    float imageHeight;
}
@end
@implementation XLTexture
- (BOOL)isSystemPhotoUrl:(NSURL *)url{
    if ([[[url scheme] lowercaseString] isEqualToString:@"assets-library"]) {
        return YES;
    }else{
        return NO;
    }
}

- (UIImage *) getImageFromPath:(NSURL *)path{
    __block UIImage* image;
    if ([self isSystemPhotoUrl:path]) {
        PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
        option.synchronous = YES;
        option.resizeMode = PHImageRequestOptionsResizeModeExact;
        
        PHAsset* asset =[[PHAsset fetchAssetsWithALAssetURLs:@[path] options:nil] objectAtIndex:0];
        
        
        int width = 600;
        [[PHImageManager defaultManager] requestImageForAsset:asset
                                                   targetSize:CGSizeMake(width, width)
                                                  contentMode:PHImageContentModeAspectFit
                                                      options:option
                                                resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                                    image = result;
                                                    
                                                }];
        
    }else{
        
        NSString* pathString = path.path;
        
        
        image = [UIImage imageWithContentsOfFile:pathString];
    }
    
    return image;
}
- (instancetype) init{
    if (!(self = [super init])) {
        return nil;
    }
    
    
    int width = 600;
    
    glGenTextures(1, &_imageTexture);
    glBindTexture(GL_TEXTURE_2D, _imageTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, width, 0, GL_BGRA, GL_UNSIGNED_BYTE, (GLvoid*)NULL);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    
    return self;
}


- (void)loadImagePath:(NSURL *)path
{
    
    
    
    int width = 600;
    
    
    
    UIImage* image = [self getImageFromPath:path];
    imageWidth = image.size.width;
    imageHeight = image.size.height;
    
    
    CGImageRef cgImage = [image CGImage];
    
    void* imageData = (void*)calloc(1, (int)width*(int)width*4);
    CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef imageContext = CGBitmapContextCreate(imageData, width, width, 8, 4*width, genericRGBColorspace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, width, width), cgImage);
    CGContextRelease(imageContext);
    CGColorSpaceRelease(genericRGBColorspace);
    
    
    glBindTexture(GL_TEXTURE_2D, _imageTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0,  width, width,GL_BGRA, GL_UNSIGNED_BYTE, (GLvoid*)imageData);
    free(imageData);
}
- (GLuint)texture{
    return _imageTexture;
}
- (float)width{
    return imageWidth;
}
- (float)height{
    return imageHeight;
}
- (void)clear{
    if (_imageTexture) {
        glDeleteTextures(1, &_imageTexture);
        _imageTexture = 0;
        
    }
}

- (void)dealloc{
    NSLog(@"%s",__func__);
    
}

@end

@interface XLTexturePool()
{
    NSMutableDictionary<NSURL *,XLTexture*>* imageTexturePool;
    int bufferCount;

}
@end
@implementation XLTexturePool
+ (XLTexturePool *)sharedInstance{
    static XLTexturePool* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}
- (instancetype)init{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    imageTexturePool = [NSMutableDictionary dictionary];
    bufferCount = 0;
    return self;
    
}

#define MAXIMAGESIZE 10

- (XLTexture *) fetchImageTextureForPath:(NSURL *)path {
    XLTexture* imageBuffer;
    if ([imageTexturePool objectForKey:path]) {
        imageBuffer = [imageTexturePool objectForKey:path];
    }else{
        
        if (!imageBuffer && imageTexturePool.count < MAXIMAGESIZE) {
            
            imageBuffer = [[XLTexture alloc] init];
            [imageBuffer loadImagePath:path];
            [imageTexturePool setObject:imageBuffer forKey:path];
            
        }else{
            imageBuffer = [imageTexturePool.allValues objectAtIndex:bufferCount%MAXIMAGESIZE];
            
            NSURL* url = [imageTexturePool.allKeys objectAtIndex:bufferCount%MAXIMAGESIZE];
            [imageTexturePool removeObjectForKey:url];
            
            [imageBuffer loadImagePath:path];
            
            [imageTexturePool setObject:imageBuffer forKey:path];
            
        }
        
        
        bufferCount++;
    }
    
    return imageBuffer;
}

- (void)clear
{
    
    if ([imageTexturePool count] > 0) {
        
        [imageTexturePool.objectEnumerator.allObjects makeObjectsPerformSelector:@selector(clear)];
        [imageTexturePool removeAllObjects];
        
        NSLog(@"%s",__func__);
    }
}
@end

