//
//  XLVideoEditor.m
//  XLVideoCore
//
//  Created by 周晓林 on 2018/5/28.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#import "XLVideoEditor.h"
#import "XLVideoCompositor.h"
#import "XLVideoCompositorInstruction.h"
#import <UIKit/UIKit.h>

@interface XLVideoEditor()
{
    CMTimeRange *passThroughTimeRange;
    CMTimeRange *transitionTimeRange;
}
@property (nonatomic, strong) AVMutableComposition *composition;
@property (nonatomic, strong) AVMutableVideoComposition *videoComposition;
@property (nonatomic, strong) AVMutableAudioMix   *audioMix;

@end

@implementation XLVideoEditor
- (CMTimeRange) passThroughTimeRangeAtIndex:(int) index
{
    return self.scenes[index].passThroughTimeRange;
}
- (CMTimeRange) transitionTimeRangeAtIndex:(int) index
{
    
    return self.scenes[index].transition.timeRange;
}
#define TIMESCALE 600

#define MAXSOURCES  18


- (void)build{
    
    self.composition = [AVMutableComposition composition];
    self.videoComposition = [AVMutableVideoComposition videoComposition];
    self.audioMix = [AVMutableAudioMix audioMix];
    self.videoComposition.customVideoCompositorClass = [XLVideoCompositor class];
    
    
    if (CGSizeEqualToSize(CGSizeZero, self.videoSize)) {
        self.videoSize = CGSizeMake(1280, 720);
    }
    
    self.composition.naturalSize = self.videoSize;
    
    AVMutableCompositionTrack *compositionVideoTracks[2*MAXSOURCES];
    AVMutableCompositionTrack *compositionAudioTracks[2*MAXSOURCES];
    
    
    NSMutableArray *inputParameters  = [NSMutableArray array];
    
    for (int i = 0; i<2*MAXSOURCES; i++) {
        compositionVideoTracks[i] = [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        compositionAudioTracks[i] = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        
    }
    
    passThroughTimeRange = (CMTimeRange*)alloca(sizeof(CMTimeRange) * [self.scenes count]);
    transitionTimeRange = (CMTimeRange*)alloca(sizeof(CMTimeRange) * [self.scenes count]);
    
    NSString *bgVideoPath = [[NSBundle mainBundle] pathForResource:@"RDVECore.bundle/black" ofType:@"mp4"];
    AVURLAsset *bgVideoAsset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:bgVideoPath]];
    
    CMTime nextClipStartTime = kCMTimeZero;
    
    NSMutableArray* instructions = [NSMutableArray array];
    
    NSMutableArray<NSMutableArray *>* trackIDsArray = [NSMutableArray array];
    
    
    for (int i = 0; i<self.scenes.count; i++) {
        XLScene* scene = self.scenes[i];
        
        
        CMTime transitionDuration = CMTimeMakeWithSeconds(scene.transition.duration, TIMESCALE);
        if (i == self.scenes.count -1) {
            transitionDuration = kCMTimeZero;
        }
        
        Float64 sceneTime = 0.0;//sceneTime与scaleDur类型必须一致，否则得出的CMTime不一致，会导致视频黑屏
        
        for (int i = 0; i<scene.vvAsset.count; i++) {
            Float64 duration = scene.vvAsset[i].duration;
            if (sceneTime <= duration) {
                sceneTime = duration;
            }
        }
        NSLog(@"sceneTime:%f",sceneTime);
        
        NSMutableArray* trackIDs = [NSMutableArray array];
        
        
        for (int j = 0; j<scene.vvAsset.count; j++) {
            
            XLAsset* vasset = scene.vvAsset[j];
            NSURL* url = vasset.url;
            
            
            CMTimeRange timeRangeInAsset = vasset.timeRange;
            
            XLAssetType type = vasset.type;
            
            NSInteger trackIndex = 2*j + i%2;
            
            AVURLAsset* asset;
            if (type == XLAssetTypeImage) {
                asset = bgVideoAsset;
                vasset.last = CMTimeGetSeconds(vasset.startTimeInScene)/sceneTime;
                
            }
            if (type == XLAssetTypeVideo) {
                asset = [AVURLAsset assetWithURL:url];
            }
            
            float speedValue = vasset.speed;
            
            
            
            
            // 放入相应轨道中  按照sceneTime1循环放入
            // sceneTime1根据sceneTime与当前媒体对象的速度计算出来 sceneTime1 = sceneTime * speed
            
            
            if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] > 0) {
                
                AVAssetTrack* clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
                vasset.transform = clipVideoTrack.preferredTransform;
                
                [compositionVideoTracks[trackIndex] insertTimeRange:timeRangeInAsset
                                                            ofTrack:clipVideoTrack
                                                             atTime:CMTimeAdd(nextClipStartTime, vasset.startTimeInScene)
                                                              error:nil];
                
                
            }
            
            
            if ([[asset tracksWithMediaType:AVMediaTypeAudio] count] > 0) {
                
                AVAssetTrack* clipAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
                
                [compositionAudioTracks[trackIndex] insertTimeRange:timeRangeInAsset
                                                            ofTrack:clipAudioTrack
                                                             atTime:CMTimeAdd(nextClipStartTime, vasset.startTimeInScene)
                                                              error:nil];
                
                
            }
            
            
            // 根据sceneTime1中缩放回sceneTime
            
            CMTimeRange speedTimeRange = timeRangeInAsset;
            Float64 scaleDur = CMTimeGetSeconds(timeRangeInAsset.duration) / speedValue;
            CMTime scaleTime = CMTimeMakeWithSeconds(scaleDur, TIMESCALE);
            if (scaleDur > 0) {
                speedTimeRange.start = CMTimeAdd(nextClipStartTime, vasset.startTimeInScene);
                [compositionVideoTracks[trackIndex] scaleTimeRange:speedTimeRange toDuration:scaleTime];
                [compositionAudioTracks[trackIndex] scaleTimeRange:speedTimeRange toDuration:scaleTime];
            }
            
            vasset.trackID = [NSNumber numberWithInt:compositionVideoTracks[trackIndex].trackID];
            vasset.assetCompositionTrack = compositionVideoTracks[trackIndex];
            
            [trackIDs addObject:[NSNumber numberWithInt:compositionVideoTracks[trackIndex].trackID]];
            
        }
        
        
        passThroughTimeRange[i] = CMTimeRangeMake(nextClipStartTime, CMTimeMakeWithSeconds(sceneTime, TIMESCALE));
        if (i>0) {
            
            CMTime previousTransitionDuration = CMTimeMakeWithSeconds(self.scenes[i-1].transition.duration, TIMESCALE);
            
            passThroughTimeRange[i].start = CMTimeAdd(passThroughTimeRange[i].start, previousTransitionDuration); // 起始时间加上前一个转场
            passThroughTimeRange[i].duration = CMTimeSubtract(passThroughTimeRange[i].duration,previousTransitionDuration); //持续时间减去前一个转场
            
        }
        if (i+1<[self.scenes count]) {
            passThroughTimeRange[i].duration = CMTimeSubtract(passThroughTimeRange[i].duration, transitionDuration);
        }
        
        nextClipStartTime = CMTimeAdd(nextClipStartTime, CMTimeMakeWithSeconds(sceneTime, TIMESCALE));
        nextClipStartTime = CMTimeSubtract(nextClipStartTime, transitionDuration);
        if (i+1<[self.scenes count]) {
            transitionTimeRange[i] = CMTimeRangeMake(nextClipStartTime, transitionDuration);
            
        }
        
        if (i == self.scenes.count - 1) {
            transitionTimeRange[i] = CMTimeRangeMake(nextClipStartTime, kCMTimeZero);
        }
        
        
        if (i == 0) {
            self.scenes[i].fixedTimeRange = CMTimeRangeMake(passThroughTimeRange[i].start, CMTimeAdd(passThroughTimeRange[i].duration, transitionTimeRange[i].duration));
        }else{
            self.scenes[i].fixedTimeRange = CMTimeRangeMake(transitionTimeRange[i-1].start, CMTimeAdd(transitionTimeRange[i-1].duration, CMTimeAdd(passThroughTimeRange[i].duration, transitionTimeRange[i].duration)));
            
        }
        
        [trackIDsArray addObject:trackIDs];
    }
    
    
    
    
    AVMutableAudioMixInputParameters* audioMixInputParmeters[2*MAXSOURCES];
    for (int i = 0; i<2*MAXSOURCES; i++) {
        audioMixInputParmeters[i] = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compositionAudioTracks[i]];
        [inputParameters addObject:audioMixInputParmeters[i]];
        
    }
    
    
    
    
    
    for (int i = 0; i<self.scenes.count; i++) {
        XLScene* scene = self.scenes[i];
        
        for (int j = 0; j<scene.vvAsset.count; j++) {
            XLAsset* vasset = scene.vvAsset[j];
            NSInteger trackIndex = 2*j + i%2;
            AVMutableAudioMixInputParameters* mixParameter = audioMixInputParmeters[trackIndex];
            vasset.mixParameter = mixParameter;
            
            mixParameter.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmVarispeed;
            mixParameter.trackID = compositionAudioTracks[trackIndex].trackID;
            
            [self checkVolumeRatioInTimeRange:scene.fixedTimeRange originalVolume:vasset.volume audioMix:mixParameter];
            
        }
        
        
    }
    
    for (int i = 0; i<self.scenes.count; i++) {
        self.scenes[i].passThroughTimeRange = passThroughTimeRange[i];
        self.scenes[i].transition.timeRange = transitionTimeRange[i];
        
    }
    
    
    
    
    for (int i = 0; i<self.scenes.count; i++) {
        
        //        NSInteger alternatingIndex = i % 2;
        
        if (i >= 0) {
            
            NSMutableArray* array = [NSMutableArray array];
            [array addObjectsFromArray:trackIDsArray[i]];
            XLVideoCompositorInstruction* videoInstruction= [[XLVideoCompositorInstruction alloc] initTransitionWithSourceTrackIDs:array forTimeRange:passThroughTimeRange[i]];
            
            XLScene* pScene = self.scenes[i];
            
            videoInstruction.scene = pScene;
            videoInstruction.customType = XLCustomTypePassThrough;
            
            [instructions addObject:videoInstruction];
            
        }
        
        if (i+1<self.scenes.count) {
            
            NSMutableArray* array = [NSMutableArray array];
            [array addObjectsFromArray:trackIDsArray[i]];
            [array addObjectsFromArray:trackIDsArray[i+1]];
            XLVideoCompositorInstruction* videoInstruction= [[XLVideoCompositorInstruction alloc] initTransitionWithSourceTrackIDs:array forTimeRange:transitionTimeRange[i]];
            
            
            videoInstruction.customType = XLCustomTypeTransition;
            
            videoInstruction.previosScene = self.scenes[i];
            
            videoInstruction.nextScene = self.scenes[i+1];
            
            [instructions addObject:videoInstruction];
        }
    }
    
    self.videoComposition.instructions = instructions;
    self.audioMix.inputParameters = inputParameters;
    self.videoComposition.frameDuration = CMTimeMake(1, self.fps);
    self.videoComposition.renderSize = self.videoSize;
    NSLog(@"videoEditor.fps:%d",self.fps);
}
- (AVPlayerItem *)playerItem{
    AVPlayerItem* playerItem = [AVPlayerItem playerItemWithAsset:_composition];
    playerItem.videoComposition = _videoComposition;
    playerItem.audioMix = _audioMix;
    return playerItem;
}

- (AVAssetExportSession*)assetExportSessionWithPreset:(NSString*)presetName
{
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:self.composition presetName:presetName];
    session.videoComposition = self.videoComposition;
    session.audioMix = self.audioMix;
    return session;
}

#pragma mark - 配音与原音比例
- (void)checkVolumeRatioInTimeRange:(CMTimeRange )timeRange
                     originalVolume:(float )originalVolume
                           audioMix:(AVMutableAudioMixInputParameters *)mixParameters{
    NSMutableArray *thisMusicRatio = [[NSMutableArray alloc]init];
    if ( self.dubbingMusics.count == 0) {
        [mixParameters setVolume:originalVolume atTime:timeRange.start];
        [mixParameters setVolumeRampFromStartVolume:originalVolume toEndVolume:originalVolume timeRange:timeRange];
        return;
    }
    CMTime start = timeRange.start;
    CMTime end = CMTimeRangeGetEnd(timeRange);
    for(int i = 0;i<self.dubbingMusics.count; i++ ){
        XLMusic * dubbingMusic = self.dubbingMusics[i];
        CMTime iStart = dubbingMusic.timeRange.start;
        CMTime iEnd   = CMTimeRangeGetEnd(dubbingMusic.timeRange);
        
        if (CMTimeCompare(iStart, start)>=0 && CMTimeCompare(iStart, end)<=0) {
            if (CMTimeCompare(iEnd, end)<=0) {
                XLMusic *iMusic = [[XLMusic alloc] init];
                iMusic.volume = dubbingMusic.volume;
                iMusic.timeRange = CMTimeRangeMake(iStart, CMTimeSubtract(iEnd, iStart));
                [thisMusicRatio addObject:iMusic];
            }else{
                XLMusic *iMusic = [[XLMusic alloc] init];
                iMusic.volume = dubbingMusic.volume;
                iMusic.timeRange = CMTimeRangeMake(iStart, CMTimeSubtract(end, iStart));
                [thisMusicRatio addObject:iMusic];
            }
        }else{
            if (CMTimeCompare(iEnd, start)>=0 && CMTimeCompare(iEnd, end)<=0) {
                if (CMTimeCompare(iStart, start)>=0) {
                    // 永远不会走这里
                    XLMusic *iMusic = [[XLMusic alloc] init];
                    iMusic.volume = dubbingMusic.volume;
                    iMusic.timeRange = CMTimeRangeMake(iStart, CMTimeSubtract(iEnd, iStart));
                    [thisMusicRatio addObject:iMusic];
                }else{
                    XLMusic *iMusic = [[XLMusic alloc] init];
                    iMusic.volume = dubbingMusic.volume;
                    iMusic.timeRange = CMTimeRangeMake(start, CMTimeSubtract(iEnd, start));
                    [thisMusicRatio addObject:iMusic];
                }
            }else{
                if(CMTimeCompare(iEnd, end)>0 && CMTimeCompare(start, iStart)>0)
                {
                    XLMusic *iMusic = [[XLMusic alloc] init];
                    iMusic.volume = dubbingMusic.volume;
                    iMusic.timeRange = CMTimeRangeMake(start, CMTimeSubtract(end, start));
                    [thisMusicRatio addObject:iMusic];
                }
            }
        }
    }
    if (thisMusicRatio.count == 0) {
        [mixParameters setVolume:originalVolume atTime:timeRange.start];
        [mixParameters setVolumeRampFromStartVolume:originalVolume toEndVolume:originalVolume timeRange:timeRange];
    }else {
        for (int i = 0; i < thisMusicRatio.count; i++) {
            XLMusic *iMusic = thisMusicRatio[i];
            float currentRatio = (1-iMusic.volume);
            
            CMTime iStart = iMusic.timeRange.start;
            CMTime iEnd = CMTimeRangeGetEnd(iMusic.timeRange);
            if (i == 0 && CMTimeCompare(iStart, start)>0) {
                [mixParameters setVolume:originalVolume atTime:start];
            }
            [mixParameters setVolume:originalVolume*currentRatio atTime:iMusic.timeRange.start];
            [mixParameters setVolumeRampFromStartVolume:originalVolume*currentRatio toEndVolume:originalVolume*currentRatio timeRange:iMusic.timeRange];
            if (CMTimeCompare(iEnd, end)<0) {
                [mixParameters setVolume:originalVolume atTime:iEnd];
            }else{
                // 保证后面原音声音片段继续有效
                [mixParameters setVolume:originalVolume atTime:iEnd];
            }
        }
    }
}


- (void)dealloc{
    NSLog(@"%s",__func__);
}
@end
