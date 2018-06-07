//
//  XLVideoCompositorInstruction.h
//  XLVideoCore
//
//  Created by 周晓林 on 2018/5/29.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "XLScene.h"

@interface XLAsset (Private)
@property (nonatomic,assign) CGAffineTransform transform;
@property (nonatomic,strong) AVCompositionTrack* _Nullable assetCompositionTrack;
@property (nonatomic,strong) NSNumber* _Nullable trackID;
@property (nonatomic,assign) float last;
@end


@interface XLScene (Private) //隐藏实现
@property (nonatomic,assign) CMTimeRange fixedTimeRange;
@property (nonatomic,assign) CMTimeRange passThroughTimeRange;
@end


typedef NS_ENUM(NSUInteger,XLCustomType) {
    XLCustomTypePassThrough,
    XLCustomTypeTransition
};

@interface XLVideoCompositorInstruction : NSObject<AVVideoCompositionInstruction>

@property (nonatomic,assign) XLCustomType                    customType;
@property (nonatomic,strong) XLScene* _Nullable              scene;
@property (nonatomic,strong) XLScene* _Nullable              nextScene;

- (id _Nullable )initPassThroughTrackID:(CMPersistentTrackID)passthroughTrackID forTimeRange:(CMTimeRange)timeRange;
- (id _Nullable )initTransitionWithSourceTrackIDs:(NSArray*_Nullable)sourceTrackIDs forTimeRange:(CMTimeRange)timeRange;
@end
