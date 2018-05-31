//
//  XLScene.m
//  XLVideoCore
//
//  Created by 周晓林 on 2018/5/28.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#import "XLScene.h"
@interface XLScene()

@end
@implementation XLScene
+ (XLScene *)scene{
    return [[self alloc] init];
}
- (void) addObject:(XLAsset *) object
{
    [self.vvAsset addObject:object];
}
- (void)setTransition:(XLTransition *)transition{
    _transition = transition;
}
- (instancetype)init {
    self = [super init];
    if (self) {
        _transition = [[XLTransition alloc] init];
        _vvAsset = [[NSMutableArray alloc] init];
    }
    
    return self;
}

@end

@implementation XLTransition
+ (XLTransition *)transition{
    return [[self alloc] init];
}
- (instancetype)init{
    self = [super init];
    if (self) {
        _type = XLVideoTransitionTypeNone;
        _duration = 2.0;
    }
    return self;
}

@end
@implementation XLMusic
- (instancetype)init{
    self = [super init];
    if (self) {
        _volume = 1.0;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone{
    XLMusic *copy = [[[self class] allocWithZone:zone] init];
    copy.url = _url;
    copy.timeRange = _timeRange;
    copy.clipTimeRange = _clipTimeRange;
    copy.volume = _volume;
    copy.isRepeat = _isRepeat;
    copy.name = _name;
    
    return copy;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    
    XLMusic *copy = [[[self class] allocWithZone:zone] init];
    copy.url = _url;
    copy.timeRange = _timeRange;
    copy.clipTimeRange = _clipTimeRange;
    copy.volume = _volume;
    copy.isRepeat = _isRepeat;
    copy.name = _name;
    
    return copy;
}
@end
@interface XLAsset()
@property (nonatomic,strong) AVURLAsset* asset;
@end

@implementation XLAsset

+ (XLAsset *)asset{
    return [[self alloc] init];
}
- (instancetype)init{
    self = [super init];
    if (self) {
        _speed = 1.0;
        _volume = 1.0;
        _isCompleteEdge = YES;
        _rectInVideo = CGRectMake(0, 0, 1, 1);
        _crop = CGRectMake(0, 0, 1, 1);
        _startTimeInScene = kCMTimeZero;
        _fillType = XLImageFillTypeFitZoomOut;
        
        _maskURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"XLVideoCore.bundle/black" ofType:@"png"]];
        
    }
    return self;
}

- (AVURLAsset *)asset{
    return [AVURLAsset assetWithURL:_url];
}
- (float)duration{
    return CMTimeGetSeconds(CMTimeAdd(_timeRange.duration, _startTimeInScene))/_speed;
}

@end


