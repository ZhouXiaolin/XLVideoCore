//
//  Program.hpp
//  Simple2D
//
//  Created by 周晓林 on 2018/5/19.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#ifndef XLGLProgram_hpp
#define XLGLProgram_hpp
#include <iostream>
namespace Simple2D {
    class XLGLProgram {
    public:
        XLGLProgram(const char* vShaderString, const char* fShaderString);
        ~XLGLProgram();
        bool link();
        void use();
        uint attribute(const char* name);
        uint uniform(const char* name);
        bool compileShader(uint* shader, uint32_t type, const char* shaderString);
    private:
        uint program;
        uint vertShader, fragShader;
    };
}

#endif /* Program_hpp */
