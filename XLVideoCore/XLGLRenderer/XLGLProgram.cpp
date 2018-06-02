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
namespace XLSimple2D {
    XLGLProgram::XLGLProgram(const char* vShaderString, const char* fShaderString){
        m_Program = glCreateProgram();
        if (!compileShader(&m_VertShader, GL_VERTEX_SHADER, vShaderString)) {
            
        }
        if (!compileShader(&m_FragShader, GL_FRAGMENT_SHADER, fShaderString)) {
            
        }
        glAttachShader(m_Program, m_VertShader);
        glAttachShader(m_Program, m_FragShader);
    }
    XLGLProgram::~XLGLProgram(){
        if (m_VertShader) {
            glDeleteShader(m_VertShader);
        }
        if (m_FragShader) {
            glDeleteShader(m_FragShader);
        }
        if (m_Program) {
            glDeleteShader(m_Program);
        }
    }
    bool XLGLProgram::link(){
        GLint status;
        glLinkProgram(m_Program);
        glGetProgramiv(m_Program, GL_LINK_STATUS, &status);
        if (status == GL_FALSE) {
            return false;
        }
        if (m_VertShader) {
            glDeleteShader(m_VertShader);
            m_VertShader = 0;
        }
        if (m_FragShader) {
            glDeleteShader(m_FragShader);
            m_FragShader = 0;
        }
        return true;
    }
    void XLGLProgram::use(){
        glUseProgram(m_Program);
    }
    uint XLGLProgram::attribute(const char* name){
        return glGetAttribLocation(m_Program, name);
    }
    uint XLGLProgram::uniform(const char* name){
        return glGetUniformLocation(m_Program, name);
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
