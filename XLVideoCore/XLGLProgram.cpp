//
//  Program.cpp
//  Simple2D
//
//  Created by 周晓林 on 2018/5/19.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#include "XLGLProgram.hpp"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
namespace Simple2D {
    XLGLProgram::XLGLProgram(const char* vShaderString, const char* fShaderString){
        program = glCreateProgram();
        if (!compileShader(&vertShader, GL_VERTEX_SHADER, vShaderString)) {
            
        }
        if (!compileShader(&fragShader, GL_FRAGMENT_SHADER, fShaderString)) {
            
        }
        glAttachShader(program, vertShader);
        glAttachShader(program, fragShader);
    }
    XLGLProgram::~XLGLProgram(){
        if (vertShader) {
            glDeleteShader(vertShader);
        }
        if (fragShader) {
            glDeleteShader(fragShader);
        }
        if (program) {
            glDeleteShader(program);
        }
    }
    bool XLGLProgram::link(){
        GLint status;
        glLinkProgram(program);
        glGetProgramiv(program, GL_LINK_STATUS, &status);
        if (status == GL_FALSE) {
            return false;
        }
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        return true;
    }
    void XLGLProgram::use(){
        glUseProgram(program);
    }
    uint XLGLProgram::attribute(const char* name){
        return glGetAttribLocation(program, name);
    }
    uint XLGLProgram::uniform(const char* name){
        return glGetUniformLocation(program, name);
    }
    bool XLGLProgram::compileShader(uint* shader, uint32_t type, const char* source){
        GLint status;
        *shader = glCreateShader(type);
        glShaderSource(*shader, 1, &source, NULL);
        glCompileShader(*shader);
        glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
        
        return status == GL_TRUE;
    }
}
