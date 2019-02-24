//
//  AudioListCell.m
//  MyRecorder
//
//  Created by FrancisKevin on 2019/2/1.
//  Copyright © 2019年 KF. All rights reserved.
//

#import "AudioListCell.h"

@interface AudioListCell ()

@property (weak, nonatomic) IBOutlet UILabel *lblAudioTitle;

@end

@implementation AudioListCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.lblAudioTitle.numberOfLines = 0;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setTitle:(NSString *)title {
    self.lblAudioTitle.text = title;
}

@end
