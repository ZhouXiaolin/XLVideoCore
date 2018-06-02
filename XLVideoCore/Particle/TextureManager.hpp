//
//  TextureManager.hpp
//  iOSSoftwareRenderer
//
//  Created by 周晓林 on 2017/11/18.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#ifndef TextureManager_hpp
#define TextureManager_hpp

#include "Common.h"
#include "Math.h"

#include <map>

namespace XLSimple2D
{
    struct DLL_export Texture
    {
        Rect size;
        Vec2 texcoords[4];
        
        GLuint texture;
    };
    
    class DLL_export TextureManager
    {
        TextureManager();
        ~TextureManager();
        
    public:
        static TextureManager* instance();
        
        Texture* getTexture(const char* filename);
        
    private:
        Texture* createTexture(const char* filename);
        
        std::map<const char*, Texture*> mTextureMap;
    };
}
#endif /* TextureManager_hpp */
