//
//  ViewController.m
//  mergeTwoVideo
//
//  Created by 1 on 2020/11/12.
//

#import "ViewController.h"
#import "videoEditor.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreServices/CoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "VideoPlayerContainerView.h"

@interface ViewController (){
    float            _transitionDuration;
    BOOL            _transitionsEnabled;
}

@property(nonatomic,strong)videoEditor *VEditor;

@property(nonatomic,strong) NSMutableArray *clips;
@property(nonatomic,strong) NSMutableArray *clipTimeRanges;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.VEditor = [[videoEditor alloc]init];
    self.clips = [NSMutableArray array];
    self.clipTimeRanges = [NSMutableArray array];
    
    // Do any additional setup after loading the view.
}

-(void)PlayBack{
    AVURLAsset *URLAsset0 = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle]pathForResource:@"eminem" ofType:@"mp4"]]];
    AVURLAsset *URLAsset1 = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle]pathForResource:@"minemine" ofType:@"mp4"]]];
    
    dispatch_group_t group = dispatch_group_create();
    NSArray *URLAssetArray = [NSArray arrayWithObjects:URLAsset0,URLAsset1, nil];
    [self loadAsset:URLAsset0 loadAssetKeyArray:URLAssetArray useDispatchGroup:group];
    [self loadAsset:URLAsset1 loadAssetKeyArray:URLAssetArray useDispatchGroup:group];
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [self synchronizeWithVideoEditor];
    });
}

-(void)loadAsset:(AVAsset *)asset loadAssetKeyArray:(NSArray *)assetArray useDispatchGroup:(dispatch_group_t)group{
    dispatch_group_enter(group);
    [asset loadValuesAsynchronouslyForKeys:assetArray completionHandler:^(){
        // 测试是否成功加载
        BOOL bSuccess = YES;
        for (NSString *key in assetArray) {
            NSError *error;
            
            if ([asset statusOfValueForKey:key error:&error] == AVKeyValueStatusFailed) {
                NSLog(@"Key value loading failed for key:%@ with error: %@", key, error);
                bSuccess = NO;
                break;
            }
        }
        if (![asset isComposable]) {
            NSLog(@"Asset is not composable");
            bSuccess = NO;
        }
        if (bSuccess && CMTimeGetSeconds(asset.duration) > 5) {
            [self.clips addObject:asset];
            [self.clipTimeRanges addObject:[NSValue valueWithCMTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0, 1), CMTimeMakeWithSeconds(5, 1))]];
        }
        else {
            NSLog(@"error ");
        }
        dispatch_group_leave(group);
    }];
}

#pragma mark ----- video editor

-(void)synchronizeWithVideoEditor{
    [self synchronizeClipsVideo];
    [self synchronizeClipsVideoTimeRange];
}

-(void)synchronizeClipsVideo{
    NSMutableArray *validClips = [NSMutableArray array];
    for (AVURLAsset *asset in self.clips) {
        if (![asset isKindOfClass:[NSNull class]]) {
            [validClips addObject:asset];
        }
    }
    
    self.VEditor.clips = validClips;
}

-(void)synchronizeClipsVideoTimeRange{
    NSMutableArray *validClipTimeRanges = [NSMutableArray array];
    for (NSValue *timeRange in self.clipTimeRanges) {
        if (! [timeRange isKindOfClass:[NSNull class]]) {
            [validClipTimeRanges addObject:timeRange];
        }
    }
    
    self.VEditor.clipsTimeRange = validClipTimeRanges;
}


@end
