//
//  ViewController.h
//  CBRecorder
//
//  Created by FrancisKevin on 2019/2/14.
//  Copyright © 2019年 KF. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController


@end

// 录音授权
@interface ViewController (RecordPermission)

- (void)checkMicrophoneAuthorization;

@end
