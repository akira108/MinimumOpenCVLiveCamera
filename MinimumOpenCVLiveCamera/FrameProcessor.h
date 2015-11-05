//
//  FrameProcessor.h
//  MinimumOpenCVLiveCamera
//
//  Created by Akira Iwaya on 2015/11/05.
//  Copyright © 2015年 akira108. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoSource.h"

#ifdef __cplusplus
#include <opencv2/opencv.hpp>
#endif

@interface FrameProcessor : NSObject<VideoSourceDelegate>

- (void)processFrame:(cv::Mat &)frame;

@end
