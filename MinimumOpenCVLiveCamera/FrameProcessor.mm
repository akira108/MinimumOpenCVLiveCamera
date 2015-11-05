//
//  FrameProcessor.m
//  MinimumOpenCVLiveCamera
//
//  Created by Akira Iwaya on 2015/11/05.
//  Copyright © 2015年 akira108. All rights reserved.
//

#import "FrameProcessor.h"

@implementation FrameProcessor

- (void)processFrame:(cv::Mat &)frame {
    // example: make it gray
    cv::cvtColor(frame, frame, cv::COLOR_BGRA2GRAY);
}

@end
