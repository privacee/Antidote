//
//  QRViewerController.m
//  Antidote
//
//  Created by Dmitry Vorobyov on 19.07.14.
//  Copyright (c) 2014 dvor. All rights reserved.
//

#import <CoreImage/CoreImage.h>

#import "QRViewerController.h"
#import "CopyLabel.h"
#import "UIViewController+Utilities.h"
#import "NSString+Utilities.h"
#import "UIView+Utilities.h"

@interface QRViewerController ()

@property (strong, nonatomic) UIButton *closeButton;
@property (strong, nonatomic) UIImageView *imageView;

@property (strong, nonatomic) NSString *text;

@end

@implementation QRViewerController

#pragma mark - Lifecycle

- (instancetype)initWithToxId:(NSString *)toxId
{
    NSString *text = [NSString stringWithFormat:@"tox:%@", toxId];
    return [self initWithText:text];
}

- (instancetype)initWithText:(NSString *)text
{
    self = [super init];

    if (self) {
        self.text = text;
    }

    return self;
}

- (void)loadView
{
    [self loadWhiteView];

    [self createCloseButton];
    [self createImageView];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    [self adjustSubviews];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [filter setDefaults];
    [filter setValue:[self.text dataUsingEncoding:NSUTF8StringEncoding]
              forKey:@"inputMessage"];

    CIImage *outputImage = [filter outputImage];

    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:outputImage.extent];

    self.imageView.image = [UIImage imageWithCGImage:cgImage scale:1.0 orientation:UIImageOrientationUp];

    CGImageRelease(cgImage);
}

#pragma mark -  Actions

- (void)closeButtonPressed
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -  Private

- (void)createCloseButton
{
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.closeButton setTitle:NSLocalizedString(@"Close", @"QRViewerController") forState:UIControlStateNormal];
    [self.closeButton addTarget:self
                         action:@selector(closeButtonPressed)
               forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:self.closeButton];
}

- (void)createImageView
{
    self.imageView = [UIImageView new];
    [self.view addSubview:self.imageView];
}

- (void)adjustSubviews
{
    CGRect frame = CGRectZero;

    {
        NSString *title = [self.closeButton titleForState:UIControlStateNormal];
        UIFont *font = self.closeButton.titleLabel.font;

        frame = CGRectZero;
        frame.size = [title stringSizeWithFont:font];
        frame.size.height = frame.size.width;
        frame.origin.x = self.view.bounds.size.width - frame.size.width - 10.0;
        frame.origin.y = 30.0;
        self.closeButton.frame = frame;
    }

    {
        frame = CGRectZero;
        frame.size.width = frame.size.height = self.view.bounds.size.width;
        frame.origin.y = (self.view.bounds.size.height - frame.size.height) / 2;
        self.imageView.frame = frame;

        self.imageView.image = [self resizeImage:self.imageView.image newSize:frame.size];
    }
}

- (UIImage *)resizeImage:(UIImage *)image newSize:(CGSize)newSize
{
    UIImage *resized = nil;

    UIGraphicsBeginImageContext(newSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    resized = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return resized;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

@end