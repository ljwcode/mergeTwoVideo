//
//  videoEditor.h
//  mergeTwoVideo
//
//  Created by 1 on 2020/11/12.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface videoEditor : NSObject

@property(nonatomic,copy)NSArray *clips;

@property(nonatomic,copy)NSArray *clipsTimeRange;

@property(nonatomic)CMTime duration;

@property(nonatomic,readonly)AVMutableComposition *composition;

@property(nonatomic,readonly)AVMutableVideoComposition *videoComposition;

@property(nonatomic,readonly)AVMutableAudioMix *audioMix;

-(AVPlayerItem *)playerItem;

-(void)buildCompositionPlayBack;

@end

NS_ASSUME_NONNULL_END
