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
    
    
    XLScene* scene = [XLScene scene];
    {
        {
            XLAsset* asset = [XLAsset asset];
            asset.type = XLAssetTypeVideo;
            asset.url = [NSURL fileURLWithPath:test1Path];
            asset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(5, 600));
            
            [scene addObject:asset];
            
        }
        
        {
            XLTransition* transition = [XLTransition transition];
            transition.type = XLVideoTransitionTypeUp;
//            transition.maskURL = [NSURL fileURLWithPath:maskPath];
            transition.duration = 1.0;
            scene.transition = transition;
        }
        
        [scenes addObject:scene];
    }

    
    XLScene* scene2 = [XLScene scene];
    {
        {
            XLAsset* asset2 = [XLAsset asset];
            asset2.type = XLAssetTypeVideo;
            asset2.url = [NSURL fileURLWithPath:test2Path];
            asset2.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(5, 600));
            
            [scene2 addObject:asset2];
        }
        
        [scenes addObject:scene2];
    }
    
    
    XLVideoEditor* editor = [XLVideoEditor videoEditor];
    editor.scenes = scenes;
    editor.fps = 30;
    editor.videoSize = CGSizeMake(720, 1280);
    
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
