//
//  OTRMessageTableViewCell.m
//  Off the Record
//
//  Created by David on 2/17/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//



#import "OTRMessageTableViewCell.h"
#import "OTRConstants.h"
#import "OTRSettingsManager.h"
#import "OTRSafariActionSheet.h"
#import "OTRAppDelegate.h"
#import "OTRChatBubbleView.h"
#import "OTRUtilities.h"
#import "OTRMessage.h"
#import "OTRDatabaseManager.h"


static CGFloat const messageTextWidthMax = 180;



@implementation OTRMessageTableViewCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.showDate = NO;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        //CreateMessageSentDateLabel
        self.dateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.dateLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.dateLabel.textColor = [UIColor grayColor];
        self.dateLabel.textAlignment = NSTextAlignmentCenter;
        self.dateLabel.font = [UIFont boldSystemFontOfSize:kOTRSentDateFontSize];
        self.dateLabel.backgroundColor = [UIColor clearColor];
        self.dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:self.dateLabel];
        
        
        //Create bubbleView
        self.bubbleView = [[OTRChatBubbleView alloc] initWithFrame:CGRectZero];
        self.bubbleView.messageTextLabel.delegate = self;
        self.bubbleView.incoming = NO;
        self.bubbleView.secure = NO;
        
        [self.bubbleView updateLayout];
        
        [self.contentView addSubview:self.bubbleView];
        
        [self setupConstraints];
    }
    
    return self;
    
}

-(void)setMessage:(OTRMessage *)message
{
    _message = message;
    self.bubbleView.messageTextLabel.text = message.text;
    self.bubbleView.delivered = message.isDelivered;
    self.bubbleView.secure = message.transportedSecurely;
    
    if (self.showDate) {
        self.dateLabel.text = [[OTRMessageTableViewCell defaultDateFormatter] stringFromDate:message.date];
    } else {
        self.dateLabel.text = nil;
    }
    
    [self.bubbleView updateLayout];
    
    [self setNeedsUpdateConstraints];
}

-(void)setupConstraints
{
    ///bubble View
    NSLayoutConstraint * constraint = [NSLayoutConstraint constraintWithItem:self.bubbleView
                                                                   attribute:NSLayoutAttributeTop
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.dateLabel
                                                                   attribute:NSLayoutAttributeBottom
                                                                  multiplier:1.0
                                                                    constant:0.0];
    [self addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.bubbleView
                                              attribute:NSLayoutAttributeCenterX
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.contentView
                                              attribute:NSLayoutAttributeCenterX
                                             multiplier:1.0
                                               constant:0.0];
    [self addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.bubbleView
                                              attribute:NSLayoutAttributeWidth
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.contentView
                                              attribute:NSLayoutAttributeWidth
                                             multiplier:1.0
                                               constant:0.0];
    [self addConstraint:constraint];
    
    //dateLabel
    constraint = [NSLayoutConstraint constraintWithItem:self.dateLabel
                                              attribute:NSLayoutAttributeTop
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.contentView
                                              attribute:NSLayoutAttributeTop
                                             multiplier:1.0
                                               constant:0.0];
    [self addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.dateLabel
                                              attribute:NSLayoutAttributeCenterX
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.contentView
                                              attribute:NSLayoutAttributeCenterX
                                             multiplier:1.0
                                               constant:0.0];
    [self addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.dateLabel
                                              attribute:NSLayoutAttributeWidth
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.contentView
                                              attribute:NSLayoutAttributeWidth
                                             multiplier:1.0
                                               constant:0.0];
    [self addConstraint:constraint];
}

- (void)updateConstraints
{
    [super updateConstraints];
    
    [self removeConstraint:dateHeightConstraint];
    CGFloat dateheight = 0.0;
    if (self.showDate) {
        dateheight = kOTRSentDateFontSize+5;
    }
    
    dateHeightConstraint = [NSLayoutConstraint constraintWithItem:self.dateLabel
                                              attribute:NSLayoutAttributeHeight
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:nil
                                              attribute:NSLayoutAttributeNotAnAttribute
                                             multiplier:1.0
                                               constant:dateheight];
    [self addConstraint:dateHeightConstraint];
    
}

+(CGSize)messageTextLabelSize:(NSString *)message
{
    TTTAttributedLabel * label = [OTRChatBubbleView defaultLabel];
    label.text = message;
    return  [label sizeThatFits:CGSizeMake(messageTextWidthMax, CGFLOAT_MAX)];
}



//Label Delegate
- (void)attributedLabel:(TTTAttributedLabel *)label
   didSelectLinkWithURL:(NSURL *)url
{
    OTRSafariActionSheet * action = [[OTRSafariActionSheet alloc] initWithUrl:url];
    [action showInView:self.superview.superview];
}

-(void)attributedLabelDidSelectDelete:(TTTAttributedLabel *)label
{
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction removeObjectForKey:self.message.uniqueId inCollection:[OTRMessage collection]];
    }];    
}

+ (CGFloat)heightForMesssage:(NSString *)message showDate:(BOOL)showDate
{
    CGFloat dateHeight = 0;
    if (showDate) {
        dateHeight = kOTRSentDateFontSize+5;
    }
    TTTAttributedLabel * label = [OTRChatBubbleView defaultLabel];
    label.text = message;
    CGSize labelSize = [label sizeThatFits:CGSizeMake(180, CGFLOAT_MAX)];
    
    CGFloat padding = 12.0;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        padding = 16.0;
    }
    
    return labelSize.height + padding + dateHeight;
}

+ (NSDateFormatter *)defaultDateFormatter
{
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MMM dd, YYYY h:mm a"];
    });
    return dateFormatter;
}

+ (NSString *)reuseIdentifier
{
    return NSStringFromClass([self class]);
}



@end
