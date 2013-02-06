//
//  ViewController.m
//  undoDraw
//
//  Created by Rob Mayoff on 2/6/13.
//  Copyright (c) 2013 Rob Mayoff. All rights reserved.
//

#import "ViewController.h"
#import "Canvas.h"
#import "CanvasView.h"
#import "UIColor+contrastingColor.h"
#import <QuartzCore/QuartzCore.h>

@interface ViewController ()

@property (strong, nonatomic) IBOutletCollection(UIBarButtonItem) NSArray *colorButtonItems;
@property (nonatomic, strong) IBOutlet CanvasView *canvasView;

@property (nonatomic, strong) Canvas *canvas;

@end

@implementation ViewController

#pragma mark - UIViewController overrides

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initCanvas];
    [self initColorButtonItems];
    [self updateColorButtonItemTitlesWithCurrentCanvasColor];
    [self initCanvasView];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateCanvasSize];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return ((1 << toInterfaceOrientation) & [self supportedInterfaceOrientations]) != 0;
}

- (NSUInteger)supportedInterfaceOrientations {
    switch ([[UIDevice currentDevice] userInterfaceIdiom]) {
        case UIUserInterfaceIdiomPad:
            return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
        default:
            return UIInterfaceOrientationMaskPortrait;
    }
}

#pragma mark - Actions

- (IBAction)save:(id)sender {
    NSLog(@"%s xxx", __func__);
}

- (IBAction)colorButtonItemWasTapped:(UIBarButtonItem *)sender {
    UIColor *color = sender.tintColor;
    self.canvas.color = color;
    [self updateColorButtonItemTitlesWithCurrentCanvasColor];
}

#pragma mark - Canvas implementation

- (void)initCanvas {
    self.canvas = [[Canvas alloc] init];

    // [UIColor blackColor] returns a color in the UIDeviceWhiteColorSpace, but the black tint in the nib is in the UIDeviceRGBColorSpace.  Stupidly, -[UIColor isEqual:] does not recognize these as the same color.  So, to make the comparison in -updateColorButtonItemTitlesWithCurrentCanvasColor work, I carefully initialize the canvas color from a color button item.
    self.canvas.color = [self.colorButtonItems[0] tintColor];
}

- (void)updateCanvasSize {
    self.canvas.size = self.canvasView.bounds.size;
    self.canvas.scale = self.canvasView.window.screen.scale;
    self.canvas.tileSize = 64.0f;
}

#pragma mark - Canvas view implementation

- (void)initCanvasView {
    self.canvasView.canvas = self.canvas;
}

#pragma mark - Color button implementation

static NSString *const kSelectedColorTitle = @"✔";
static NSString *const kUnselectedColorTitle = @"   ";

- (void)initColorButtonItems {
    NSSet *possibleTitles = [NSSet setWithArray:@[ kSelectedColorTitle, kUnselectedColorTitle ]];
    for (UIBarButtonItem *item in self.colorButtonItems) {
        item.possibleTitles = possibleTitles;
        NSDictionary *tribs = @{
                 UITextAttributeFont: [UIFont systemFontOfSize:24],
                 UITextAttributeTextColor: [item.tintColor contrastingColor]
         };
        [item setTitleTextAttributes:tribs forState:UIControlStateNormal];
    }
}

- (void)updateColorButtonItemTitlesWithCurrentCanvasColor {
    UIColor *color = self.canvas.color;
    for (UIBarButtonItem *item in self.colorButtonItems) {
        item.title = [item.tintColor isEqual:color] ? kSelectedColorTitle : kUnselectedColorTitle;
    }
}

#pragma mark - Touch handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = touches.anyObject;
    [self.canvas moveTo:[touch locationInView:self.canvasView]];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = touches.anyObject;
    [self lineTo:[touch locationInView:self.canvasView]];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = touches.anyObject;
    [self lineTo:[touch locationInView:self.canvasView]];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"%s %@", __func__, touches);
}

- (void)lineTo:(CGPoint)point {
    // Prevent Core Animation from automatically animating the tile updates with a fade.
    [CATransaction begin]; {
        [CATransaction setDisableActions:YES];
        [self.canvas lineTo:point];
    } [CATransaction commit];
}

@end
