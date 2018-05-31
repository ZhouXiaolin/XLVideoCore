//
//  XLGLProgram.h
//  XLVideoCore
//
//  Created by 周晓林 on 2018/5/31.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface XLGLProgram : NSObject
{
    NSMutableArray  *attributes;
    NSMutableArray  *uniforms;
    GLuint          program,
    vertShader,
    fragShader;
}

@property(readwrite, nonatomic) BOOL initialized;
@property(readwrite, copy, nonatomic) NSString *vertexShaderLog;
@property(readwrite, copy, nonatomic) NSString *fragmentShaderLog;
@property(readwrite, copy, nonatomic) NSString *programLog;

- (id)initWithVertexShaderString:(NSString *)vShaderString
            fragmentShaderString:(NSString *)fShaderString;
- (id)initWithVertexShaderString:(NSString *)vShaderString
          fragmentShaderFilename:(NSString *)fShaderFilename;
- (id)initWithVertexShaderFilename:(NSString *)vShaderFilename
            fragmentShaderFilename:(NSString *)fShaderFilename;
- (GLuint)attributeIndex:(NSString *)attributeName;
- (GLuint)uniformIndex:(NSString *)uniformName;
- (BOOL)link;
- (void)use;
- (void)validate;
@end
