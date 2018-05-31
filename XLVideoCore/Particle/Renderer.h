//
//  Renderer.h
//  VideoCore
//
//  Created by 周晓林 on 2017/11/21.
//  Copyright © 2017年 Solaren. All rights reserved.
//

#ifndef Renderer_h
#define Renderer_h
#include "Common.h"
#include "Math.h"

#include <vector>
#include <map>
namespace Simple2D {
    class Texture;
    enum Flag
    {
        DEFAULT_TEXCOORD = 1,
        DEFAULT_INDEX = 2
    };
    enum RenderType
    {
        RENDER_TYPE_LINES,
        RENDER_TYPE_TRIANGLES,
        RENDER_TYPE_TEXTURE
    };
    
    enum ShaderUsage
    {
        SU_TEXT            = 0,
        SU_TEXTURE        = 1,
        SU_GEOMETRY        = 2
    };
    
    struct RenderUnit
    {
        RenderUnit()
        {
            flag = 0;
        }
        
        Vec3* pPositions;
        Vec2* pTexcoords;
        int nPositionCount;
        
        Color* color;
        bool bSameColor;
        
        GLuint* pIndices;
        int nIndexCount;
        
        Texture* texture;
        
        int flag;
        RenderType renderType;
        ShaderUsage shaderUsage;
    };
    template<typename T>
    class ResizeVector
    {
    public:
        std::vector<T> vector;
        
        T& operator[](size_t index)
        {
            return vector[index];
        }
        
        void clear(bool delete_ptr = false)
        {
            if ( delete_ptr ) {
                for ( auto& ele : vector ) delete ele;
            }
            vector.clear();
        }
        
        void resize(int new_size)
        {
            if ( vector.size() < new_size ) {
                vector.resize(new_size);
            }
        }
    };
    
    class VertexData
    {
    public:
        ResizeVector<Vec3> positions;
        ResizeVector<Vec2> texcoords;
        ResizeVector<Color> colors;
        ResizeVector<GLuint> indices;
        
        int nPositionCount;
        int nIndexCount;
        bool bHasTexcoord;
        
        int flag;
        RenderType renderType;
        ShaderUsage shaderUsage;
        
        void clear()
        {
            nPositionCount = 0;
            nIndexCount = 0;
        }
    };
    
}
#endif /* Renderer_h */
