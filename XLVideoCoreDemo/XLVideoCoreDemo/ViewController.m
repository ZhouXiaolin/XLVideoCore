//
//  ViewController.m
//  XLVideoCoreDemo
//
//  Created by 周晓林 on 2018/5/28.
//  Copyright © 2018年 Solaren. All rights reserved.
//

#import "ViewController.h"
#import "XLVideoCore.h"
#import <AVFoundation/AVFoundation.h>
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString* test1Path = [[NSBundle mainBundle] pathForResource:@"test1" ofType:@"MP4"];
    NSString* test2Path = [[NSBundle mainBundle] pathForResource:@"test2" ofType:@"MOV"];
    NSString* maskPath = [[NSBundle mainBundle] pathForResource:@"004" ofType:@"JPG"];
    
    NSMutableArray* scenes = [NSMutableArray array];
    XLScene* scene = [[XLScene alloc] init];
    
    XLAsset* asset = [[XLAsset alloc] init];
    asset.type = XLAssetTypeVideo;
    asset.url = [NSURL fileURLWithPath:test1Path];
    asset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(5, 600));
    
    [scene.vvAsset addObject:asset];
    
    XLTransition* transition = [[XLTransition alloc] init];
    transition.type = XLVideoTransitionTypeMask;
    transition.maskURL = [NSURL fileURLWithPath:maskPath];
    
    scene.transition = transition;
    
    XLScene* scene2 = [[XLScene alloc] init];
    
    XLAsset* asset2 = [[XLAsset alloc] init];
    asset2.type = XLAssetTypeVideo;
    asset2.url = [NSURL fileURLWithPath:test2Path];
    asset2.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(5, 600));
    
    [scene2.vvAsset addObject:asset2];
    
    [scenes addObject:scene];
    [scenes addObject:scene2];
    
    XLVideoEditor* editor = [[XLVideoEditor alloc] init];
    editor.scenes = scenes;
    editor.fps = 30;
    editor.videoSize = CGSizeMake(720, 1080);
    
    [editor build];
    
    
    AVPlayerItem* playerItem = editor.playerItem;
    
    
    
    AVPlayer* player = [AVPlayer playerWithPlayerItem:playerItem];
    

    AVPlayerLayer* playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.frame = [UIScreen mainScreen].bounds;
    [self.view.layer addSublayer:playerLayer];
    
    [player play];
    
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
