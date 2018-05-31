//
//  XLVideoEditor.h
//  XLVideoCore
//
//  Created by 周晓林 on 2018/5/28.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "XLScene.h"



@interface XLVideoEditor : NSObject

@property (nonatomic, assign) CGSize videoSize;
@property (nonatomic, assign) int fps;
@property (nonatomic, strong) NSMutableArray<XLScene*>* scenes;
@property (nonatomic, strong) XLMusic* music;
@property (nonatomic, strong) NSMutableArray<XLMusic *>* dubbingMusics;
@property (nonatomic, assign) float totalTime;

- (void) build;
- (AVPlayerItem *) playerItem;
- (AVAssetExportSession*)assetExportSessionWithPreset:(NSString*)presetName;
@end
