//
//  ViewController.m
//  VideoRecordText
//
//

#import "ViewController.h"


#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

#define WIDTH [UIScreen mainScreen].bounds.size.width
#define HEIGHT [UIScreen mainScreen].bounds.size.height


@interface ViewController ()<AVCaptureFileOutputRecordingDelegate>

@property (strong,nonatomic) AVCaptureSession *captureSession;//负责输入和输出设置之间的数据传递
@property (strong,nonatomic) AVCaptureDeviceInput *captureDeviceInput;//负责从AVCaptureDevice获得输入数据
@property (strong,nonatomic) AVCaptureMovieFileOutput *captureMovieFileOutput;//视频输出流
@property (strong,nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;//相机拍摄预览图层

@property (nonatomic,strong)NSString * fileName;//文件夹名
@property (nonatomic,assign)int fileNum;//文件名
@property (nonatomic,strong)NSMutableArray * fileUrlArr;//文件路径数组


@property (nonatomic,strong)MPMoviePlayerController * mediaV;

@property (nonatomic,strong)UIView * playBcgV;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _fileUrlArr = [[NSMutableArray alloc]init];
    _fileName = [NSString stringWithFormat:@"%d",(int)[[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970]];
    _fileNum = 0;
    
    [self createPlayBcgV];//播放视图
    
    [self createUI];
    
    // Do any additional setup after loading the view, typically from a nib.
}


#pragma mark ---------------------隐藏播放控制器---------------------
-(void)hideBtnClick:(UIButton *)btn{
    
    NSLog(@"隐藏");
    
    [_mediaV stop];
    
    _playBcgV.hidden = YES;
    
    
}

-(void)createUI{
    
    
    UIView * layerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, WIDTH, HEIGHT-140)];
    
    layerView.backgroundColor = [UIColor blackColor];
    
    
    //初始化会话
    _captureSession=[[AVCaptureSession alloc]init];
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if (granted) {
        }else{
            NSLog(@"未获取摄像头权限");
        }
    }];
    //获得输入设备（视频）
    AVCaptureDevice *captureDevice=[self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];//取得后置摄像头
    if (!captureDevice) {
        NSLog(@"取得后置摄像头时出现问题.");
        return;
    }
    
    NSError *error=nil;
    //根据输入设备初始化设备输入对象，用于获得输入数据
    _captureDeviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:captureDevice error:&error];
    if (error) {
        NSLog(@"取得视频设备输入对象时出错，错误原因：%@",error.localizedDescription);
        return;
    }
    //添加一个输入设备（音频）
    AVCaptureDevice *audioCaptureDevice=[[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];

    AVCaptureDeviceInput *audioCaptureDeviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:audioCaptureDevice error:&error];
    if (error) {
        NSLog(@"取得音频设备输入对象时出错，错误原因：%@",error.localizedDescription);
        return;
    }
    //初始化设备输出对象，用于获得输出数据
    _captureMovieFileOutput=[[AVCaptureMovieFileOutput alloc]init];
    
    //将设备输入添加到会话中
    if ([_captureSession canAddInput:_captureDeviceInput]) {
        [_captureSession addInput:_captureDeviceInput];
        [_captureSession addInput:audioCaptureDeviceInput];
        AVCaptureConnection *captureConnection=[_captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([captureConnection isVideoStabilizationSupported ]) {
            captureConnection.preferredVideoStabilizationMode=AVCaptureVideoStabilizationModeAuto;
        }
    }
    
    //将设备输出添加到会话中
    if ([_captureSession canAddOutput:_captureMovieFileOutput]) {
        [_captureSession addOutput:_captureMovieFileOutput];
    }
    //创建视频预览层，用于实时展示摄像头状态
    _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.captureSession];
    
    _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    CALayer *layer= layerView.layer;
    layer.masksToBounds=YES;
    _captureVideoPreviewLayer.frame = CGRectMake(0, 0, WIDTH, HEIGHT);
    
    //将视频预览层添加到界面中
    [layer addSublayer:_captureVideoPreviewLayer];
    
    
    [self.captureSession startRunning];
    
    
    [self.view addSubview:layerView];
    
    [self createButton];
}


#pragma mark --------------------清空按钮-------------------
-(void)clearBtnClick:(UIButton *)btn{
    NSLog(@"清空");

    UIButton * button = (UIButton *)[self.view viewWithTag:100];
    
    if (button.selected) {
        return;
    }

    NSFileManager* fileManager=[NSFileManager defaultManager];
    
    NSString *pathDocuments = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *createPath = [NSString stringWithFormat:@"%@/myVidio", pathDocuments];
    
    // 判断文件夹是否存在，如果存在，清空
    if ([[NSFileManager defaultManager] fileExistsAtPath:createPath]) {
        [fileManager removeItemAtPath:createPath error:nil];
    }

}

#pragma mark --------------------视频录制-------------------
-(void)recordStartOrPause:(UIButton *)btn{
    
    btn.selected = !btn.selected;

    if (btn.selected) {//点击开始方法
        NSLog(@"录制");

        NSString * pathDocument = [self checkPath];
        [_fileUrlArr addObject:pathDocument];
        
        [_captureMovieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:pathDocument] recordingDelegate:self];
        
        _fileNum ++;
        
    }else{//停止方法
        NSLog(@"停止");

         [_captureMovieFileOutput stopRecording];
    }
    
}

-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{
    
    NSLog(@"录制完成");
    
}

#pragma mark --------------------录制完成-------------------
-(void)finishBtnClick:(UIButton *)btn{//点击进行视频合成操作并跳转到PlayViewController
    UIButton * button = (UIButton *)[self.view viewWithTag:100];
    
    if (button.selected) {
        return;
        
    }
    NSLog(@"完成");

    if (_fileUrlArr.count < 1) {
        return;
    }
    //合成后视频出处路径
    NSString *pathDocuments = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *createPath = [NSString stringWithFormat:@"%@/myVidio/%@/%@.mp4", pathDocuments,_fileName,_fileName];
    
    

    if (_fileUrlArr.count > 1) {
    
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
            
            AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
            
            AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                                preferredTrackID:kCMPersistentTrackID_Invalid];
            AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                preferredTrackID:kCMPersistentTrackID_Invalid];
            
            CMTime totalDuration = kCMTimeZero;
            
            for (int i = 0; i < _fileUrlArr.count; i++) {
                AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:_fileUrlArr[i]]];
                NSError *erroraudio = nil;//获取AVAsset中的音频 或者视频
                AVAssetTrack *assetAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];//向通道内加入音频或者视频
                //                BOOL ba =
                [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                    ofTrack:assetAudioTrack
                                     atTime:totalDuration
                                      error:&erroraudio];
                
                //        NSLog(@"erroraudio:%@%d",erroraudio,ba);
                NSError *errorVideo = nil;
                AVAssetTrack *assetVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo]firstObject];
                
                //                BOOL bl =
                [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                    ofTrack:assetVideoTrack
                                     atTime:totalDuration
                                      error:&errorVideo];
                
                //        NSLog(@"errorVideo:%@%d",errorVideo,bl);
                totalDuration = CMTimeAdd(totalDuration, asset.duration);
                
                videoComposition.frameDuration = CMTimeMake(1, 30);
                //视频输出尺寸
                videoComposition.renderSize = CGSizeMake(assetVideoTrack.naturalSize.height,assetVideoTrack.naturalSize.height*(HEIGHT/(HEIGHT-140)));

                
                AVMutableVideoCompositionInstruction * avMutableVideoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
                
                [avMutableVideoCompositionInstruction setTimeRange:CMTimeRangeMake(kCMTimeZero, [mixComposition duration])];
                
                AVMutableVideoCompositionLayerInstruction * avMutableVideoCompositionLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:assetAudioTrack];
                
                [avMutableVideoCompositionLayerInstruction setTransform:assetVideoTrack.preferredTransform atTime:kCMTimeZero];
                
                avMutableVideoCompositionInstruction.layerInstructions = [NSArray arrayWithObject:avMutableVideoCompositionLayerInstruction];
                
                videoComposition.instructions = [NSArray arrayWithObject:avMutableVideoCompositionInstruction];
                
                
            }
            
            NSFileManager* fileManager=[NSFileManager defaultManager];
            BOOL blHave=[[NSFileManager defaultManager] fileExistsAtPath:createPath];
            if (blHave) {
                [fileManager removeItemAtPath:createPath error:nil];
            }
            
            
            NSURL *mergeFileURL = [NSURL fileURLWithPath:createPath];
            //        NSLog(@"starvideorecordVC: 345 outpath = %@",outpath);
            AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetMediumQuality];
            exporter.outputURL = mergeFileURL;
            
            exporter.videoComposition = videoComposition;
            exporter.outputFileType = AVFileTypeMPEG4;
            exporter.shouldOptimizeForNetworkUse = YES;
            [exporter exportAsynchronouslyWithCompletionHandler:^{
                NSLog(@" exporter%@",exporter.error);
                if (exporter.status == AVAssetExportSessionStatusCompleted) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        _playBcgV.hidden = NO;
                        
                        [self.view bringSubviewToFront:_playBcgV];
                        
                        _mediaV.contentURL = mergeFileURL;
                        
                        [_mediaV prepareToPlay];
                        [_mediaV play];
                        
                        
                    });
                }
            }];
            
            
        });
    }else{
        
        _playBcgV.hidden = NO;
        
        [self.view bringSubviewToFront:_playBcgV];
        
        _mediaV.contentURL = [NSURL fileURLWithPath:_fileUrlArr[0]];
        
        
        [_mediaV prepareToPlay];
        [_mediaV play];
    }
    
}



#pragma mark - -----------------获取摄像头设备---------------------

/**
 *  取得指定位置的摄像头
 *
 *  @param position 摄像头位置
 *
 *  @return 摄像头设备
 */
-(AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position{
    
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position]==position) {
            return camera;
        }
    }
    return nil;
}

#pragma mark --------------------检查文件路径------------------
-(NSString *)checkPath{
    NSFileManager* fileManager=[NSFileManager defaultManager];
    
    NSString *pathDocuments = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *createPath = [NSString stringWithFormat:@"%@/myVidio/%@", pathDocuments,_fileName];
    
    // 判断文件夹是否存在，如果不存在，则创建
    if (![[NSFileManager defaultManager] fileExistsAtPath:createPath]) {
        [fileManager createDirectoryAtPath:createPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *pathDocument = [NSString stringWithFormat:@"%@/%d.mp4",createPath,_fileNum];
    
    BOOL blHave=[[NSFileManager defaultManager] fileExistsAtPath:pathDocument];
    if (blHave) {
        [fileManager removeItemAtPath:pathDocument error:nil];
    }

    return pathDocument;
    
}



#pragma mark ---------------------创建控制按钮----------------------
-(void)createButton{
    
    UIButton * recordBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    
    recordBtn.frame = CGRectMake(30, HEIGHT-100, WIDTH/3-40, 40);
    
    [recordBtn setTitle:@"开始" forState:UIControlStateNormal];
    [recordBtn setTitle:@"停止" forState:UIControlStateSelected];
    recordBtn.tag = 100;
    recordBtn.backgroundColor = [UIColor blackColor];
    
    recordBtn.layer.cornerRadius = 20;
    recordBtn.clipsToBounds = YES;
    
    
    [recordBtn addTarget:self action:@selector(recordStartOrPause:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:recordBtn];
    
    
    UIButton * finishBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    
    finishBtn.frame = CGRectMake(WIDTH/3+20, HEIGHT-100, WIDTH/3-40, 40);
    
    [finishBtn setTitle:@"完成" forState:UIControlStateNormal];
    finishBtn.backgroundColor = [UIColor blackColor];
    
    finishBtn.layer.cornerRadius = 20;
    finishBtn.clipsToBounds = YES;
    [finishBtn addTarget:self action:@selector(finishBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:finishBtn];
    
    
    
    UIButton * clearBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    
    clearBtn.frame = CGRectMake(WIDTH/3 * 2 + 10, HEIGHT-100, WIDTH/3-40, 40);
    [clearBtn setTitle:@"清空" forState:UIControlStateNormal];
    clearBtn.backgroundColor = [UIColor blackColor];
    
    clearBtn.layer.cornerRadius = 20;
    clearBtn.clipsToBounds = YES;
    [clearBtn addTarget:self action:@selector(clearBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:clearBtn];
    
    
}

#pragma mark ---------------------创建播放视图----------------------

-(void)createPlayBcgV{
    _playBcgV = [[UIView alloc]initWithFrame:CGRectMake(0, 0, WIDTH, HEIGHT)];
    
    _playBcgV.backgroundColor = [UIColor blackColor];
    
    
    _mediaV = [[MPMoviePlayerController alloc]init];
    
    _mediaV.view.frame = CGRectMake(0, 0, WIDTH, HEIGHT-120);
    _mediaV.view.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    
    [_playBcgV addSubview:_mediaV.view];
    
    
    
    UIButton * hideBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    
    hideBtn.frame = CGRectMake(30, HEIGHT-100, WIDTH-60, 40);
    
    [hideBtn setTitle:@"隐藏" forState:UIControlStateNormal];
    
    hideBtn.backgroundColor = [UIColor whiteColor];
    [hideBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    hideBtn.layer.cornerRadius = 20;
    hideBtn.clipsToBounds = YES;
    
    [hideBtn addTarget:self action:@selector(hideBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    [_playBcgV addSubview:hideBtn];
    
    
    _playBcgV.hidden = YES;
    
    [self.view addSubview:_playBcgV];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
