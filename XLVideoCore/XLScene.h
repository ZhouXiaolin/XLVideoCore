//
//  XLScene.h
//  XLVideoCore
//
//  Created by 周晓林 on 2018/5/28.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


typedef NS_ENUM(NSInteger,  XLVideoTransitionType) {
    XLVideoTransitionTypeNone = 0,
    XLVideoTransitionTypeLeft ,        //左推
    XLVideoTransitionTypeRight,        //右推
    XLVideoTransitionTypeUp,           //上推
    XLVideoTransitionTypeDown,         //下推
    XLVideoTransitionTypeFade,         //淡入
    XLVideoTransitionTypeBlinkBlack,   //闪黑
    XLVideoTransitionTypeBlinkWhite,   //闪白
    XLVideoTransitionTypeMask          //Mask
};

typedef NS_ENUM(NSInteger, XLAssetType) {
    XLAssetTypeVideo,
    XLAssetTypeImage
};

@class XLTransition;
@class XLAsset;

/*   场景，场景是一个视频的基本组合单位，视频由多个场景组成，一个场景包含多个展示资源与一个过渡效果
 *
 */
@interface XLScene : NSObject
@property (nonatomic,strong) NSMutableArray<XLAsset*>* _Nonnull  vvAsset;
@property (nonatomic,strong) XLTransition* _Nullable transition;
+ (XLScene*) scene;
- (void) addObject:(XLAsset *) object;
- (void) setTransition:(XLTransition*) transition;
@end

@interface XLMusic : NSObject<NSCopying,NSMutableCopying>

/**使用音乐地址
 */
@property (nonatomic, strong) NSURL * _Nullable url;

/**音乐总时间范围
 */
@property (nonatomic, assign) CMTimeRange timeRange;

/**音乐截取时间范围
 */
@property (nonatomic, assign) CMTimeRange clipTimeRange;

/**音乐名称
 */
@property (nonatomic, strong) NSString *_Nullable name;

/**音量(0.0-1.0)，默认为1.0
 */
@property (nonatomic, assign) float volume;

/**是否重复播放
 */
@property (nonatomic, assign) BOOL isRepeat;

@end




/* 转场 当前场景如何向后一个场景过渡
 *
 */
@interface XLTransition : NSObject


/*
 *  转场类型
 */
@property (nonatomic,assign)  XLVideoTransitionType   type;

/*
 *  持续时间
 */
@property (nonatomic,assign) CGFloat duration;

/*
 *  特效灰度图地址
 */
@property (nonatomic,strong) NSURL* _Nullable maskURL;

@property (nonatomic,assign) CMTimeRange timeRange;


+ (XLTransition *) transition;

@end


typedef NS_ENUM(NSInteger, XLImageFillType) {
    XLImageFillTypeFull, // 全填充
    XLImageFillTypeFit,  // 适配 静止
    XLImageFillTypeFitZoomOut, // 适配 缩小
    XLImageFillTypeFitZoomIn   // 适配 放大
    
};


/*
 *  资源 图片与视频资源是同级的
 */
@interface XLAsset : NSObject


@property (nonatomic,strong) NSURL* _Nullable url;

@property (nonatomic,strong) AVMutableAudioMixInputParameters* _Nullable mixParameter;
/*
 *  视频最后一帧图片地址
 */
@property (nonatomic,strong) NSString* _Nullable lastFrameUrlString;

/*
 *  资源类型 图片 或者 视频
 */
@property (nonatomic,assign) XLAssetType      type;


@property (nonatomic,assign) XLImageFillType  fillType;

/*
 *  资源显示时间段  开始 与 持续时间
 *  图片设置持续时间  视频可以指定时间段
 */
@property (nonatomic,assign) CMTimeRange      timeRange;

/*
 *
 *  在场景中开始时间
 */
@property (nonatomic,assign) CMTime startTimeInScene;
/*
 *  播放速度 作用在图片段只会表现为播放时间改变 作用在视频上可以加速或者减速
 */
@property (nonatomic,assign) float            speed;

/*
 *  音量  默认为1.0
 */
@property (nonatomic,assign) float            volume;

/**视频(或图片)裁剪范围
 */
@property (nonatomic,assign) CGRect           crop;
/**视频(或图片)旋转角度
 */
@property (nonatomic,assign) double           rotate;
/**是否上下镜像
 */
@property (nonatomic,assign) BOOL             isVerticalMirror;
/**是否左右镜像
 */
@property (nonatomic,assign) BOOL             isHorizontalMirror;

@property (nonatomic,assign) CGRect           rectInVideo; // 在video中的范围

@property (nonatomic,assign) float            maxAlphaInVideo; //灰度范围
@property (nonatomic,assign) float            minAlphaInVideo;

@property (nonatomic,assign) BOOL             isCompleteEdge;

/*
 *
 */
@property (nonatomic,readonly) float duration;

@property (nonatomic, strong) NSURL* _Nullable maskURL;

+ (XLAsset *) asset;
@end

