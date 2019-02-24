//
//  ViewController.m
//  CBRecorder
//
//  Created by FrancisKevin on 2019/2/14.
//  Copyright © 2019年 KF. All rights reserved.
//

#import "ViewController.h"

#import <AVFoundation/AVFoundation.h>
#import "RecorderListController.h"
#import "AudioFormatConstant.h"

@interface ViewController () <AVAudioRecorderDelegate>

@property (nonatomic, strong) AVAudioRecorder *audioRecorder;

@property (nonatomic, strong) NSTimer *myTimer;
@property (nonatomic, assign) NSInteger count;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 检查录音权限
    [self checkMicrophoneAuthorization];
    
    [self setupAudioSession];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:)   name:AVAudioSessionRouteChangeNotification object:nil];//设置通知
}

//通知方法的实现
- (void)audioRouteChangeListenerCallback:(NSNotification *)notification {
    NSDictionary *interuptionDict = notification.userInfo;
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    switch (routeChangeReason) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            NSLog(@"AVAudioSessionRouteChangeReasonNewDeviceAvailable");
            NSLog(@"耳机插入");
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            NSLog(@"AVAudioSessionRouteChangeReasonOldDeviceUnavailable");
            NSLog(@"耳机拔出，停止播放操作");
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            // called at start - also when other audio wants to play
            NSLog(@"AVAudioSessionRouteChangeReasonCategoryChange");
            break;
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Setup
- (void)setupAudioSession {
    // 1.创建音频会话
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    // 设置录音类别（这里选用录音后可回放录音类型）
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
//    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];
    
    /*
    NSError *error;
    BOOL success = [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];// 设置为扬声器模式
    if(!success)
    {
        NSLog(@"error doing outputaudioportoverride - %@", [error localizedDescription]);
    }
    //*/
}

- (void)setupAudioInputPort:(AVAudioSessionPortOverride)port {
    NSError *error;
    BOOL success = [[AVAudioSession sharedInstance] overrideOutputAudioPort:port error:&error];// 设置为扬声器模式
    if(!success)
    {
        NSLog(@"error doing outputaudioportoverride - %@", [error localizedDescription]);
    }
}

#pragma mark - Setter & Getter
- (AVAudioRecorder *)audioRecorder {
    if (!_audioRecorder) {
        // 获取沙盒Document文件路径
        NSString *filePath = [self getFilePath];
        
        // 保存录音文件的路径url
        NSURL *url = [NSURL URLWithString:filePath];
        // 创建录音格式设置setting
        NSDictionary *setting = [self getAudioSetting];
        // error
        NSError *error = nil;
        
        _audioRecorder = [[AVAudioRecorder alloc] initWithURL:url settings:setting error:&error];
        _audioRecorder.delegate = self;
        _audioRecorder.meteringEnabled = YES;// 监控声波
        if (error) {
            NSLog(@"创建录音机对象时发生错误，错误信息：%@", error.localizedDescription);
            return nil;
        }
    }
    return _audioRecorder;
}

// 文件路径
- (NSString *)getFilePath {
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *filePath = @"";
    NSDate *nowDate = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-M-d---HH:mm:ss";
    NSString *dateStr = [formatter stringFromDate:nowDate];
    if ([fm fileExistsAtPath:documentPath]) {
        filePath = [NSString stringWithFormat:@"%@/Record:%@%@", documentPath, dateStr, kAudioFileFormat_caf];
    }
    return filePath;
}

- (NSDictionary *)getAudioSetting {
    // 录音设置信息字典
    NSMutableDictionary *recordSettings = [[NSMutableDictionary alloc] init];
    // 编码格式
    [recordSettings setValue:@(kAudioFormatLinearPCM) forKey: AVFormatIDKey];
    // 采样率（8000.0，11025.0，22050.0，44100.0），22050的采样频率是常用的音频采样率，而44100采样率即是CD级别
    [recordSettings setValue:@(8000.0) forKey: AVSampleRateKey];
    // 通道数(单通道、双通道)
    //[recordSettings setValue:@(2) forKey: AVNumberOfChannelsKey];
    // 比特率，每个采样点位数（有8、16、24、32bit），表示用多少bit去保存采样值
    //[recordSettings setValue:@(16) forKey: AVLinearPCMBitDepthKey];
    
    // 每秒占用多少kb=采样率*通道数*比特率/10000
    // 比如采样率8000.0，单通道，比特率16bit，这样每秒占用约是12.8kb
    
    // 音频质量
    [recordSettings setValue:@(AVAudioQualityMin) forKey: AVEncoderAudioQualityKey];
    
    return [NSDictionary dictionaryWithDictionary:recordSettings];
}
/*
// 录音设置
- (NSDictionary *)getAudioSetting {
    // LinearPCM 是iOS的一种无损编码格式,但是体积较为庞大
    // 录音设置信息字典
    NSMutableDictionary *recordSettings = [[NSMutableDictionary alloc] init];
    // 编码格式
    [recordSettings setValue:@(kAudioFormatLinearPCM) forKey: AVFormatIDKey];
    // 采样率
    [recordSettings setValue:@(22050.0) forKey: AVSampleRateKey];
    // 通道数(双通道)
    [recordSettings setValue:@(2) forKey: AVNumberOfChannelsKey];
    // 比特率，每个采样点位数（有8、16、24、32bit），表示用多少bit去保存采样值
    [recordSettings setValue:@(16) forKey: AVLinearPCMBitDepthKey];
    // 采用浮点采样
    [recordSettings setValue:@YES forKey: AVLinearPCMIsFloatKey];
    // 音频质量
    [recordSettings setValue:@(AVAudioQualityMin) forKey: AVEncoderAudioQualityKey];
    // 比特采样率
    [recordSettings setValue:@(128000) forKey: AVEncoderBitRateKey];
    // 其他可选的设置
    // ... ...
    
    return [NSDictionary dictionaryWithDictionary:recordSettings];
}
*/
#pragma mark - AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    if (flag) {
        NSLog(@"录音完成");
    } else {
        NSLog(@"录音被打断");
    }
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError * __nullable)error {
    NSLog(@"录音编码错误：%@", error);
}

#pragma mark - Button Action
// 单次录音
- (IBAction)recorder1Action:(id)sender {
    NSLog(@"开始一段录音");
    // 开始录音前确保没有录音&&创建文件准备录音
    if (![self.audioRecorder isRecording] && [self.audioRecorder prepareToRecord]) {
        // 开始录音，会取得用户使用麦克风的同意
        [self.audioRecorder record];
    }
}

// 停止单个录音
- (IBAction)stopRecorderAction:(id)sender {
    NSLog(@"结束单个录音");
    [self.audioRecorder stop];
    _audioRecorder.delegate = nil;
    _audioRecorder = nil;
}

// 单次录音，分段保存
- (IBAction)recorder2Action:(id)sender {
    NSLog(@"开始分段录音");
    
    if ([self startRecorder]) {
        [self startTimer];
    }
}

// 停止分段录音
- (IBAction)stopRecorder2Action:(id)sender {
    NSLog(@"结束分段录音");
    
    [self stopTimer];
    
    [self stopRecorder];
}


- (IBAction)openRecordListAction:(id)sender {
    RecorderListController *vc = [RecorderListController createRecorderListController];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - 连续录音
- (BOOL)startRecorder {
    // 开始录音前确保没有录音&&创建文件准备录音
    if (![self.audioRecorder isRecording] && [self.audioRecorder prepareToRecord]) {
        // 开始录音，会取得用户使用麦克风的同意
        [self.audioRecorder record];
        
        return YES;
    } else {
        return NO;
    }
}

- (void)stopRecorder {
    [self.audioRecorder stop];
    _audioRecorder.delegate = nil;
    _audioRecorder = nil;
}

- (void)startTimer {
    self.count = 0;
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(repeatAction) userInfo:nil repeats:YES];
    //    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    [timer setFireDate:[NSDate distantPast]];
    self.myTimer = timer;
    NSLog(@"计时器开始");
}

- (void)stopTimer {
    //    [self.myTimer invalidate];
    //    self.myTimer = nil;
    
    [self.myTimer setFireDate:[NSDate distantFuture]];
    self.myTimer = nil;
    NSLog(@"计时器停止");
}

// 每5秒重复一次录音操作：停止当前录音，打印当前录音的信息，开始下一段录音
- (void)repeatAction {
    if (self.count == 5) {
        self.count = 1;
        
        NSURL *audioURL = self.audioRecorder.url;
        
        [self stopRecorder];
        
        [self getAudioFileWithPath:audioURL];
        
        [self startRecorder];
        
        return;
    }
    self.count ++;
    NSLog(@"计时器-录音%ld秒", self.count);
}

// 打印当前录音文件的路径和时长
- (void)getAudioFileWithPath:(NSURL *)url {
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:url.absoluteString]) {
        //        NSLog(@"文件已存在：%@", url.absoluteString);
        AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:url options:nil];
        CMTime audioDuration = audioAsset.duration;
        float audioDurationSeconds = CMTimeGetSeconds(audioDuration);
        NSLog(@"录音文件(%@)有 %f 秒", url.absoluteString, audioDurationSeconds);
    }
}

@end

#pragma mark - 录音授权
@implementation ViewController (RecordPermission)
// 检查录音权限
- (void)checkMicrophoneAuthorization {
    // 获取音频输入的授权状态
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (status) {
        case AVAuthorizationStatusNotDetermined:
        {
            // App第一次打开，且没有询问过授权操作
            AVAudioSession *audioSession = [AVAudioSession sharedInstance];
            if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
                // 发起提示框询问用户
                [audioSession requestRecordPermission:^(BOOL granted) {
                    if (granted) {
                        // Microphone enabled code
                        NSLog(@"用户同意使用麦克风");
                    }
                    else {
                        // Microphone disabled code
                        NSLog(@"用户不同意使用麦克风");
                    }
                }];
            }
        }
            break;
            
        case AVAuthorizationStatusAuthorized:
        {
            // 已授权
        }
            break;
            
        case AVAuthorizationStatusRestricted:// 此应用程序没有被授权访问,可能是家长控制权限
        case AVAuthorizationStatusDenied:// 用户已明确拒绝访问权限，可以提示用户去打开授权
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"麦克风权限" message:@"您已禁用麦克风权限，需要在设置-隐私-麦克风中进行开启。是否开启？" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"开启" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                UIApplication *sharedApplication = [UIApplication sharedApplication];
                if ([sharedApplication canOpenURL:url]) {
                    if (@available(iOS 10.0, *)) {
                        [sharedApplication openURL:url options:@{} completionHandler:^(BOOL success) {
                            
                        }];
                    } else {
                        [sharedApplication openURL:url];
                    }
                }
            }];
            [alert addAction:confirmAction];
            
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                NSLog(@"什么都不干");
            }];
            [alert addAction:cancelAction];
            
            [self.navigationController presentViewController:alert animated:YES completion:^{
                ;
            }];
        }
            break;
            
        default:
            break;
    }
}

@end
