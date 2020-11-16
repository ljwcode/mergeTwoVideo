//
//  videoEditor.m
//  mergeTwoVideo
//
//  Created by 1 on 2020/11/12.
//

#import "videoEditor.h"

@interface videoEditor()

@property(nonatomic,readwrite)AVMutableComposition *composition;

@property(nonatomic,readwrite)AVMutableVideoComposition *videoComposition;

@property(nonatomic,readwrite)AVMutableAudioMix *audioMix;



@end

@implementation videoEditor

/*
  音视频合并核心方法
 */
-(void)buildTransitionCompostion:(AVMutableComposition *)composition andVideoComposition:(AVMutableVideoComposition *)videoComposition andAudioMix:(AVMutableAudioMix *)audioMix{
    CMTime NextClipTime = kCMTimeZero;
    NSUInteger clipsCount = [self.clips count];
    CMTime transitionDuration = self.duration;
    for(int i = 0;i<clipsCount;i++){
        NSValue *clipsTimeRange = [self.clipsTimeRange objectAtIndex:i];
        if(clipsTimeRange){
            CMTime halfClipsDuration = [clipsTimeRange CMTimeRangeValue].duration;
            halfClipsDuration.timescale *= 2;
            transitionDuration = CMTimeMinimum(transitionDuration, halfClipsDuration);
        }
    }
    
    AVMutableCompositionTrack *videoCompositionTrack[2];
    AVMutableCompositionTrack *audioCompositionTrack[2];
    videoCompositionTrack[0] = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    videoCompositionTrack[1] = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    audioCompositionTrack[0] = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    audioCompositionTrack[1] = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    CMTimeRange *passthroughTimeRange = alloca(sizeof(CMTimeRange) * clipsCount);
    CMTimeRange *transitionTimeRange = alloca(sizeof(CMTimeRange) * clipsCount);
    
    for(int i=0;i<clipsCount;i++){
        NSValue *clipsTimeRange = [self.clipsTimeRange objectAtIndex:i];
        NSUInteger index = i % 2;
        AVURLAsset *urlAsset = [self.clips objectAtIndex:i];
        CMTimeRange assetTimeRange;
        if(clipsTimeRange){
            assetTimeRange = [clipsTimeRange CMTimeRangeValue];
        }else{
            assetTimeRange = CMTimeRangeMake(kCMTimeZero, [urlAsset duration]);
        }
        AVAssetTrack *assetVideoTrack = [[urlAsset tracksWithMediaType:AVMediaTypeVideo]objectAtIndex:0];
        NSError *error = nil;
        [videoCompositionTrack[index] insertTimeRange:assetTimeRange ofTrack:assetVideoTrack atTime:NextClipTime error:&error];
        
        AVAssetTrack *assetAudioTrack = [[urlAsset tracksWithMediaType:AVMediaTypeAudio]objectAtIndex:0];
        [audioCompositionTrack[index] insertTimeRange:assetTimeRange ofTrack:assetAudioTrack atTime:NextClipTime error:&error];
        
        passthroughTimeRange[i] = CMTimeRangeMake(NextClipTime, assetTimeRange.duration);
        if(i>0){
            passthroughTimeRange[i].start = CMTimeAdd(passthroughTimeRange[i].start, transitionDuration);
            passthroughTimeRange[i].duration = CMTimeSubtract(passthroughTimeRange[i].duration,transitionDuration);
        }
        if(i+1 < clipsCount){
            passthroughTimeRange[i].duration = CMTimeSubtract(passthroughTimeRange[i].duration, transitionDuration);
        }
        NextClipTime = CMTimeAdd(NextClipTime, assetTimeRange.duration);
        NextClipTime = CMTimeSubtract(NextClipTime, transitionDuration);
        
        if(i+1 < clipsCount){
            transitionTimeRange[i] = CMTimeRangeMake(NextClipTime, transitionDuration);
        }
    }
    
    NSMutableArray *InstracitonArray = [NSMutableArray array];
    NSMutableArray<AVAudioMixInputParameters *> *audioTrackMixArray = [NSMutableArray<AVAudioMixInputParameters *> array];
    for(int i=0;i<clipsCount;i++){
        NSUInteger index = i % 2;
        AVMutableVideoCompositionInstruction *videoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction]; //新建视频操作指令，长度为passthroughTimeRange
        videoCompositionInstruction.timeRange = passthroughTimeRange[i];
        AVMutableVideoCompositionLayerInstruction *videoCompositionLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoCompositionTrack[index]];
        
        videoCompositionInstruction.layerInstructions = [NSArray arrayWithObject:videoCompositionLayerInstruction];
        [InstracitonArray addObject:videoCompositionInstruction];
        if(i+1 < clipsCount){
            AVMutableVideoCompositionInstruction *VCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction]; //新建视频操作指令，长度为TransitionTimeRange
            VCompositionInstruction.timeRange = transitionTimeRange[i];
            AVMutableVideoCompositionLayerInstruction *fromVCLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoCompositionTrack[index]];
            AVMutableVideoCompositionLayerInstruction *toVCLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoCompositionTrack[1-index]];
            
            [fromVCLayerInstruction setOpacityRampFromStartOpacity:1 toEndOpacity:0 timeRange:transitionTimeRange[i]];
            [toVCLayerInstruction setOpacityRampFromStartOpacity:0 toEndOpacity:1 timeRange:transitionTimeRange[i]];
            
            VCompositionInstruction.layerInstructions = [NSArray arrayWithObjects:fromVCLayerInstruction,toVCLayerInstruction, nil];
            [InstracitonArray addObject:VCompositionInstruction];
            
            AVMutableAudioMixInputParameters *audioMixIP1 = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioCompositionTrack[index]];
            [audioMixIP1 setVolumeRampFromStartVolume:1 toEndVolume:0 timeRange:transitionTimeRange[i]];
            
            AVMutableAudioMixInputParameters *audioMixIP2 = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioCompositionTrack[1-index]];
            [audioMixIP2 setVolumeRampFromStartVolume:0 toEndVolume:1 timeRange:transitionTimeRange[i]];
            
            [audioTrackMixArray addObject:audioMixIP1];
            [audioTrackMixArray addObject: audioMixIP2];
        }
    }
    audioMix.inputParameters = audioTrackMixArray;
    videoComposition.instructions = InstracitonArray;
    
}

-(AVPlayerItem *)playerItem{
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
    playerItem.audioMix = self.audioMix;
    playerItem.videoComposition = self.videoComposition;
    return playerItem;
}

-(void)buildCompositionPlayBack{
    if ( (self.clips == nil) || [self.clips count] == 0 ) {
        self.composition = nil;
        self.videoComposition = nil;
        return;
    }
    
    CGSize videoSize = [[self.clips objectAtIndex:0] naturalSize];
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableVideoComposition *videoComposition = nil;
    AVMutableAudioMix *audioMix = nil;
    
    composition.naturalSize = videoSize;
    
    videoComposition = [AVMutableVideoComposition videoComposition];
    audioMix = [AVMutableAudioMix audioMix];
    
    [self buildTransitionCompostion:composition andVideoComposition:videoComposition andAudioMix:audioMix];
    
    if (videoComposition) {
        // 通用属性
        videoComposition.frameDuration = CMTimeMake(1, 30); // 30 fps
        videoComposition.renderSize = videoSize;
    }
    
    self.composition = composition;
    self.videoComposition = videoComposition;
    self.audioMix = audioMix;
}

@end
