//
//  VideoSource.m
//  MinimumOpenCVLiveCamera
//
//  Created by Akira Iwaya on 2015/11/05.
//  Copyright © 2015年 akira108. All rights reserved.
//

#import "VideoSource.h"
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>

using namespace cv;
using namespace std;

@interface VideoSource () <AVCaptureVideoDataOutputSampleBufferDelegate>
@property (strong, nonatomic) CALayer *previewLayer;
@property (strong, nonatomic) AVCaptureSession *captureSession;
@end

@implementation VideoSource

- (void)setTargetView:(UIView *)targetView {
    if (self.previewLayer == nil) {
        return;
    }
    [targetView.layer addSublayer:self.previewLayer];
    self.previewLayer.contentsGravity = kCAGravityResizeAspectFill;
    self.previewLayer.frame = targetView.bounds;
    self.previewLayer.affineTransform = CGAffineTransformMakeRotation(M_PI / 2);
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _captureSession = [[AVCaptureSession alloc] init];
        _captureSession.sessionPreset = AVCaptureSessionPreset640x480;
        
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        NSError *error = nil;
        AVCaptureDeviceInput *input = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
        [_captureSession addInput:input];
        
        AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
        output.videoSettings = @{(NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
        output.alwaysDiscardsLateVideoFrames = YES;
        [_captureSession addOutput:output];
        
        dispatch_queue_t queue = dispatch_queue_create("VideoQueue", DISPATCH_QUEUE_SERIAL);
        [output setSampleBufferDelegate:self queue:queue];
        
        _previewLayer = [CALayer layer];

    }
    
    return self;
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    uint8_t *base;
    int width, height, bytesPerRow;
    base = (uint8_t*)CVPixelBufferGetBaseAddress(imageBuffer);
    width = (int)CVPixelBufferGetWidth(imageBuffer);
    height = (int)CVPixelBufferGetHeight(imageBuffer);
    bytesPerRow = (int)CVPixelBufferGetBytesPerRow(imageBuffer);
    
    Mat mat = Mat(height, width, CV_8UC4, base);
    
    //Processing here
    [self.delegate processFrame:mat];
    
    CGImageRef imageRef = [self CGImageFromCVMat:mat];
    dispatch_sync(dispatch_get_main_queue(), ^{
       self.previewLayer.contents = (__bridge id)imageRef;
    });
    
    CGImageRelease(imageRef);
    CVPixelBufferUnlockBaseAddress( imageBuffer, 0 );
}

- (void)start {
    [self.captureSession startRunning];
}

- (void)stop {
    [self.captureSession stopRunning];
}

- (CGImageRef)CGImageFromCVMat:(Mat)cvMat {
    if (cvMat.elemSize() == 4) {
        cv::cvtColor(cvMat, cvMat, COLOR_BGRA2RGBA);
    }
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return imageRef;
}


@end
