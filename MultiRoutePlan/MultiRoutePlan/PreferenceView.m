//
//  PreferenceView.m
//  AMapNaviKit
//
//  Created by AutoNavi on 6/27/16.
//  Copyright © 2016 AutoNavi. All rights reserved.
//

#import "PreferenceView.h"

@interface PreferenceView ()

@property (nonatomic, strong) UIButton *avoidCongestion;
@property (nonatomic, strong) UIButton *avoidCost;
@property (nonatomic, strong) UIButton *avoidHighway;
@property (nonatomic, strong) UIButton *prioritiseHighway;

@end

@implementation PreferenceView

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self buildPreferenceView];
    }
    return self;
}

- (void)buildPreferenceView
{
    double singleWidth = (CGRectGetWidth(self.bounds) - 50) / 4.0;
    
    self.avoidCongestion = [self buildButtonForTitle:@"躲避拥堵"];
    [self.avoidCongestion addTarget:self action:@selector(avoidCongestionAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.avoidCongestion setFrame:CGRectMake(10, 0, singleWidth, CGRectGetHeight(self.bounds))];
    [self addSubview:self.avoidCongestion];
    
    self.avoidCost = [self buildButtonForTitle:@"避免收费"];
    [self.avoidCost addTarget:self action:@selector(avoidCostAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.avoidCost setFrame:CGRectMake(20 + singleWidth, 0, singleWidth, CGRectGetHeight(self.bounds))];
    [self addSubview:self.avoidCost];
    
    self.avoidHighway = [self buildButtonForTitle:@"不走高速"];
    [self.avoidHighway addTarget:self action:@selector(avoidHighwayAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.avoidHighway setFrame:CGRectMake(30 + singleWidth*2, 0, singleWidth, CGRectGetHeight(self.bounds))];
    [self addSubview:self.avoidHighway];
    
    self.prioritiseHighway = [self buildButtonForTitle:@"高速优先"];
    [self.prioritiseHighway addTarget:self action:@selector(prioritiseHighwayAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.prioritiseHighway setFrame:CGRectMake(40 + singleWidth*3, 0, singleWidth, CGRectGetHeight(self.bounds))];
    [self addSubview:self.prioritiseHighway];
}

#pragma mark - Interface

- (AMapNaviDrivingStrategy)strategyWithIsMultiple:(BOOL)isMultiple
{
    return ConvertDrivingPreferenceToDrivingStrategy(isMultiple,
                                                     self.avoidCongestion.selected,
                                                     self.avoidHighway.selected,
                                                     self.avoidCost.selected,
                                                     self.prioritiseHighway.selected);
}

#pragma mark - Handle Button

- (UIButton *)buildButtonForTitle:(NSString *)title
{
    UIButton *reBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    
    reBtn.layer.borderColor  = [UIColor lightGrayColor].CGColor;
    reBtn.layer.borderWidth  = 1.0;
    reBtn.layer.cornerRadius = 5;
    
    [reBtn setBounds:CGRectMake(0, 0, 80, 30)];
    [reBtn setTitle:title forState:UIControlStateNormal];
    [reBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [reBtn setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
    reBtn.titleLabel.font = [UIFont systemFontOfSize:13.0];
    
    return reBtn;
}

- (void)changeButtonState:(UIButton *)button selected:(BOOL)selected
{
    button.selected = selected;
    button.layer.borderColor = button.selected ? [UIColor redColor].CGColor : [UIColor lightGrayColor].CGColor;
}

#pragma mark - Button Action

- (void)avoidCongestionAction:(UIButton *)sender
{
    [self changeButtonState:sender selected:!sender.selected];
}

- (void)avoidCostAction:(UIButton *)sender
{
    [self changeButtonState:sender selected:!sender.selected];
    
    if (sender.selected == YES)
    {
        [self changeButtonState:self.prioritiseHighway selected:NO];
    }
}

- (void)avoidHighwayAction:(UIButton *)sender
{
    [self changeButtonState:sender selected:!sender.selected];
    
    if (sender.selected == YES)
    {
        [self changeButtonState:self.prioritiseHighway selected:NO];
    }
}

- (void)prioritiseHighwayAction:(UIButton *)sender
{
    [self changeButtonState:sender selected:!sender.selected];
    
    if (sender.selected == YES)
    {
        [self changeButtonState:self.avoidCost selected:NO];
        [self changeButtonState:self.avoidHighway selected:NO];
    }
}

@end
