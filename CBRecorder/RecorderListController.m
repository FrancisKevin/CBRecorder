//
//  RecorderListController.m
//  CBRecorder
//
//  Created by FrancisKevin on 2019/2/19.
//  Copyright © 2019年 KF. All rights reserved.
//

#import "RecorderListController.h"

#import "AudioListCell.h"
#import <AVFoundation/AVFoundation.h>
#import "AudioFormatConstant.h"

static NSString *kCellIdentifier = @"AudioListCellIdentifier";

@interface RecorderListController () <UITableViewDataSource, UITableViewDelegate, AVAudioPlayerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *recordTableView;

@property (nonatomic, strong) NSMutableArray *listData;
@property (nonatomic, strong) NSMutableArray *urlListData;

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

@end

@implementation RecorderListController

+ (instancetype)createRecorderListController {
    RecorderListController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"RecorderListController"];
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    self.view.backgroundColor = [UIColor whiteColor];
    
    [self initData];
    
    [self setupAudioSession];
    
    [self setupTableView];
    
    [self.recordTableView reloadData];
}

- (void)initData {
    // 获取沙盒Document文件路径
    NSString *sandBoxPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:sandBoxPath]) {
        NSArray *fileArr = [fm contentsOfDirectoryAtPath:sandBoxPath error:nil];
        //        self.listData = [[NSMutableArray alloc] initWithArray:fileArr];
        self.listData = [NSMutableArray new];
        
        self.urlListData = [NSMutableArray new];
        for (NSString *fileName in fileArr) {
            if ([fileName containsString:kAudioFileFormat_mp3] ||
                [fileName containsString:kAudioFileFormat_caf] ||
                [fileName containsString:kAudioFileFormat_wav]) {
                NSString *filePath = [NSString stringWithFormat:@"%@/%@", sandBoxPath, fileName];
                [self.listData addObject:fileName];
                [self.urlListData addObject:filePath];
            }
        }
    }
}

- (void)setupAudioSession {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    // 设置录音类别（这里选用录音后可回放录音类型）
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];
    
    //*
    if ([self isUseHeadphones] == NO) {
        NSError *error;
        BOOL success = [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];// 设置为扬声器模式
        if(!success)
        {
            NSLog(@"error doing outputaudioportoverride - %@", [error localizedDescription]);
        }
    }
     //*/
}

- (BOOL)isUseHeadphones {
    AVAudioSessionRouteDescription *routeDesc = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription *portDesc in [routeDesc outputs]) {
        if ([[portDesc portType] isEqualToString:AVAudioSessionPortHeadphones])
            return YES;
    }
    return NO;
}

- (void)setupTableView {
    UITableView *tableView = self.recordTableView;
    
    [tableView registerNib:[UINib nibWithNibName:@"AudioListCell" bundle:nil] forCellReuseIdentifier:kCellIdentifier];
    tableView.rowHeight = 80.f;
    tableView.dataSource = self;
    tableView.delegate = self;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.listData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AudioListCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    NSString *fileName = self.listData[indexPath.row];
    
    NSString *sandBoxPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *tempMusicPath = [NSString stringWithFormat:@"%@/%@", sandBoxPath, fileName];
    NSURL *tempUrl = [NSURL fileURLWithPath:tempMusicPath];
    AVAsset *asset = [AVAsset assetWithURL:tempUrl];
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:asset];
    
    if ([compatiblePresets containsObject:AVAssetExportPresetMediumQuality]) {
        
        AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:tempUrl options:nil];
        CMTime audioDuration = audioAsset.duration;
        float audioDurationSeconds = CMTimeGetSeconds(audioDuration);
        NSData *audioData = [NSData dataWithContentsOfURL:tempUrl];
        CGFloat size = audioData.length*1.0/1024;
        fileName = [NSString stringWithFormat:@"%@\n%.1f 秒/%.0f kb", fileName, audioDurationSeconds, size];
    }
    
    cell.title = fileName;
    
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self playAudioWithPath:self.listData[indexPath.row]];
}

#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (flag) {
        NSLog(@"录音播放完成");
    } else {
        NSLog(@"录音播放被打断");
    }
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error {
    NSLog(@"录音播放解码错误：%@", error);
}

#pragma mark - Audio Player
- (void)playAudioWithPath:(NSString *)path {
    NSString *sandBoxPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", sandBoxPath, path];
    
    [self playAudioWithAbsolutePath:filePath];
}

- (void)playAudioWithAbsolutePath:(NSString *)absolutePath {
    [self.audioPlayer stop];
    self.audioPlayer = nil;
    
    NSURL *url = [NSURL fileURLWithPath:absolutePath];
    NSError *error = nil;
    AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    audioPlayer.delegate = self;
    audioPlayer.numberOfLoops = 0;
    audioPlayer.volume = 1.0f;
    [audioPlayer prepareToPlay];
    
    if(error){
        NSLog(@"初始化播放器过程发生错误,错误信息:%@",error.localizedDescription);
    } else {
        [audioPlayer play];
        self.audioPlayer = audioPlayer;
    }
}

#pragma mark - Button Action
- (IBAction)stopAction:(id)sender {
    [self.audioPlayer stop];
}

- (IBAction)playMultipleAudioAction:(id)sender {
    [self composeAudioWithFilePaths:self.urlListData];
}

#pragma mark - Custom Method
- (void)composeAudioWithFilePaths:(NSArray *)filePaths {
    NSString *sandBoxPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *dictionaryPath = [NSString stringWithFormat:@"%@/compose", sandBoxPath];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // 删除并创建新目录
    if ([fm fileExistsAtPath:dictionaryPath]) {
        [fm removeItemAtPath:dictionaryPath error:nil];
    }
    [fm createDirectoryAtPath:dictionaryPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    
    AVMutableComposition *composition = [AVMutableComposition composition];// 音频轨道
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:0];
    Float64 tmpDuration =0.0f;
    
    for (NSString *filePath in filePaths) {
        AVURLAsset *tempAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:filePath] options:nil];
        CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, tempAsset.duration);
        AVAssetTrack *audioAssetTrack = [[tempAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        NSError *error;
        [audioTrack insertTimeRange:timeRange ofTrack:audioAssetTrack atTime:CMTimeMakeWithSeconds(tmpDuration, 0) error:&error];
        tmpDuration += CMTimeGetSeconds(tempAsset.duration);
    }
    
    NSString *outputPath = [NSString stringWithFormat:@"%@/compose1.m4a", dictionaryPath];
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
    session.outputURL = [NSURL fileURLWithPath:outputPath];
    session.outputFileType = AVFileTypeAppleM4A;
    
    __weak typeof(self) weakSelf = self;
    [session exportAsynchronouslyWithCompletionHandler:^{
        if (session.status == AVAssetExportSessionStatusCompleted) {
            NSLog(@"拼接成功----%@", outputPath);
            [weakSelf playAudioWithAbsolutePath:outputPath];
            
        } else {
            // 其他情况, 具体请看这里`AVAssetExportSessionStatus`.
            NSLog(@"%@", session.error);
        }
    }];
}

@end
