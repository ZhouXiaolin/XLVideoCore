//
//  XLVideoCompositorInstruction.m
//  XLVideoCore
//
//  Created by 周晓林 on 2018/5/29.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#import "XLVideoCompositorInstruction.h"
#import <objc/runtime.h>

static NSString* transformName = @"transform";
static NSString* trackIDName = @"trackID";
static NSString* lastName = @"last";
static NSString* assetCompositionTrackName = @"assetCompositionTrack";

@implementation XLAsset (Private)
- (void)setAssetCompositionTrack:(AVCompositionTrack *)assetCompositionTrack{
    objc_setAssociatedObject(self, &assetCompositionTrackName, assetCompositionTrack, OBJC_ASSOCIATION_COPY);
    
}
- (AVCompositionTrack *)assetCompositionTrack{
    return objc_getAssociatedObject(self, &assetCompositionTrackName);
}
- (void)setTransform:(CGAffineTransform)transform{
    NSValue* value = [NSValue value:&transform withObjCType:@encode(CGAffineTransform)];
    objc_setAssociatedObject(self, &transformName, value, OBJC_ASSOCIATION_COPY);
}
- (CGAffineTransform)transform{
    CGAffineTransform transform;
    NSValue* value = objc_getAssociatedObject(self, &transformName);
    [value getValue:&transform];
    return transform;
}
- (void)setTrackID:(NSNumber *)trackID{
    objc_setAssociatedObject(self, &trackIDName, trackID, OBJC_ASSOCIATION_COPY);
}
- (NSNumber *)trackID{
    return objc_getAssociatedObject(self, &trackIDName);
}
- (void)setLast:(float)last{
    NSNumber* number = [NSNumber numberWithFloat:last];
    objc_setAssociatedObject(self, &lastName, number, OBJC_ASSOCIATION_COPY);
}
- (float)last{
    NSNumber* number = objc_getAssociatedObject(self, &lastName);
    return [number floatValue];
}
@end



static NSString* fixedTimeRangeName = @"fixedTimeRange";
static NSString* passThroughTimeRangeName = @"passThroughTimeRange";
@implementation XLScene (Private)
- (void)setFixedTimeRange:(CMTimeRange)fixedTimeRange{
    NSValue* value = [NSValue valueWithBytes:&fixedTimeRange objCType:@encode(CMTimeRange)];
    objc_setAssociatedObject(self, &fixedTimeRangeName, value, OBJC_ASSOCIATION_COPY);
}
- (CMTimeRange)fixedTimeRange{
    CMTimeRange range;
    NSValue* value =  objc_getAssociatedObject(self, &fixedTimeRangeName);
    [value getValue:&range];
    return range;
}
- (void)setPassThroughTimeRange:(CMTimeRange)passThroughTimeRange{
    NSValue* value = [NSValue valueWithBytes:&passThroughTimeRange objCType:@encode(CMTimeRange)];
    objc_setAssociatedObject(self, &passThroughTimeRangeName, value, OBJC_ASSOCIATION_COPY);
}
- (CMTimeRange)passThroughTimeRange{
    CMTimeRange range;
    NSValue* value = objc_getAssociatedObject(self,&(passThroughTimeRangeName));
    [value getValue:&range];
    return range;
}
@end


@implementation XLVideoCompositorInstruction
@synthesize timeRange = _timeRange;
@synthesize enablePostProcessing = _enablePostProcessing;
@synthesize containsTweening = _containsTweening;
@synthesize requiredSourceTrackIDs = _requiredSourceTrackIDs;
@synthesize passthroughTrackID = _passthroughTrackID;

- (id)initPassThroughTrackID:(CMPersistentTrackID)passthroughTrackID forTimeRange:(CMTimeRange)timeRange // 不执行compositor
{
    self = [super init];
    if (self) {
        _passthroughTrackID = passthroughTrackID;
        _requiredSourceTrackIDs = nil;
        _timeRange = timeRange;
        _containsTweening = FALSE;
        _enablePostProcessing = FALSE;
    }
    
    return self;
}

- (id)initTransitionWithSourceTrackIDs:(NSArray *)sourceTrackIDs forTimeRange:(CMTimeRange)timeRange  // 执行compositor
{
    self = [super init];
    if (self) {
        _requiredSourceTrackIDs = sourceTrackIDs;
        _passthroughTrackID = kCMPersistentTrackID_Invalid;
        _timeRange = timeRange;
        _containsTweening = TRUE;
        _enablePostProcessing = FALSE;
    }
    
    return self;
}

@end
