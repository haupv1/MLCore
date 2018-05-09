//
//  ViewController.m
//  CoreMLTest
//
//  Created by Pham Van Hau on 5/9/18.
//  Copyright © 2018 Pham Van Hau. All rights reserved.
//

#import "ViewController.h"
#import "AVFoundation/AVFoundation.h"
#import "Vision/Vision.h"
#import "Resnet50.h"
@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>
@property (retain, nonatomic) NSArray *results;
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.label.textColor = [UIColor whiteColor];
    self.label.translatesAutoresizingMaskIntoConstraints = false;
    self.label.text = @"Label";
    self.label.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:30];
    self.label.frame = CGRectMake(self.view.frame.size.width/2 -100, self.view.frame.size.height/2 -50, 200, 100);
//    self.label.centerXAnchor
//    label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true;
//    label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true;
    [self setupCaptureSession];
    [self.view addSubview:self.label];
    // Do any additional setup after loading the view, typically from a nib.
}
- (void) setupCaptureSession{
    // creates a new capture session
    AVCaptureSession* captureSession = [[AVCaptureSession alloc] init];
    
    // search for available capture devices
    AVCaptureDevice* availableDevices = [AVCaptureDevice defaultDeviceWithDeviceType: AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
    
    // get capture device, add device input to capture session
    [captureSession addInput:[AVCaptureDeviceInput deviceInputWithDevice:availableDevices error:nil]];
    // setup output, add output to capture session
    AVCaptureVideoDataOutput* captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    [captureSession addOutput:captureOutput];
    [captureOutput setSampleBufferDelegate:self queue:dispatch_queue_create("videoQueue",DISPATCH_QUEUE_SERIAL)];
    AVCaptureVideoPreviewLayer* previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
    previewLayer.frame = self.view.frame;
    [self.view.layer addSublayer:previewLayer];
    [captureSession startRunning];
}
- (void) captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    NSLog(@"enter here");
    MLModel* m = [[[Resnet50 alloc] init] model];
    VNCoreMLModel* model = [VNCoreMLModel modelForMLModel:m error:nil];
    VNCoreMLRequest* request = [[VNCoreMLRequest alloc] initWithModel:model completionHandler:(^(VNRequest * _Nonnull request, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.results = [request.results copy];
            VNClassificationObservation* Observation = ((VNClassificationObservation *)(self.results[0]));
            self.label.text = Observation.identifier;
            NSLog(@"identify as %@",Observation.identifier);
        });
    })];
    NSDictionary *options = [[NSDictionary alloc] init];
    NSArray *reqArray = @[request];
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // executes request
    VNImageRequestHandler* handler = [[VNImageRequestHandler alloc] initWithCVPixelBuffer:imageBuffer options:options];
    dispatch_async(dispatch_get_main_queue(), ^{
        [handler performRequests:reqArray error:nil];
    });
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
