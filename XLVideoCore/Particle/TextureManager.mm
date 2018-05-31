//
//  TextureManager.cpp
//  iOSSoftwareRenderer
//
//  Created by 周晓林 on 2017/11/18.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#include "TextureManager.hpp"
#import <UIKit/UIKit.h>
namespace Simple2D{
    TextureManager::TextureManager(){
        
    }
    
    TextureManager::~TextureManager(){
        for (auto ele : mTextureMap) {
            glDeleteTextures(1, &ele.second->texture);
            delete ele.second;
        }
        mTextureMap.clear();
    }
    
    TextureManager* TextureManager::instance(){
        static TextureManager tm;
        return &tm;
    }
    
    Texture* TextureManager::getTexture(const char *filename){
        auto it = mTextureMap.find(filename);
        if (it == mTextureMap.end()) {
            Texture* texture = this->createTexture(filename);
            mTextureMap.insert(std::make_pair(filename, texture));
            return texture;
        }else{
            return it->second;
        }
    }
    
    Texture* TextureManager::createTexture(const char *filename){
        GLuint texture = -1;
        
        unsigned char* image_data = nullptr;

        UIImage* image = [UIImage imageWithContentsOfFile:[NSString stringWithCString:filename encoding:NSUTF8StringEncoding]];
        
        int width = image.size.width;
        int height = image.size.height;
        CGImageRef cgImage = [image CGImage];
        image_data = (unsigned char*) malloc(sizeof(unsigned char) * width * height * 4);
        
        CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
        CGContextRef imageContext = CGBitmapContextCreate(image_data, width, height, 8, 4*width, genericRGBColorspace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, width, height), cgImage);
        CGContextRelease(imageContext);
        CGColorSpaceRelease(genericRGBColorspace);
        
        
        glGenTextures(1, &texture);
        glBindTexture(GL_TEXTURE_2D, texture);
        

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, image_data);
        glBindTexture(GL_TEXTURE_2D, 0);
        
        free(image_data);
        
        Texture* tex = new Texture();
        tex->texture = texture;
        tex->size.set(0, 0, width, height);
        tex->texcoords[0].set(0, 0);
        tex->texcoords[1].set(0, 1);
        tex->texcoords[2].set(1, 1);
        tex->texcoords[3].set(1, 0);
        
        return tex;
        
    }
    
}
