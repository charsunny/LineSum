//
//  CubeContainerView.h
//  LineSum
//
//  Created by Lanston Peng on 4/20/14.
//  Copyright (c) 2014 Vtm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CubeEntity.h"
#import "CubePath.h"
#import "Util.h"
#import "ScoreBoardView.h"

@protocol CubeContainerDelegate <NSObject>

@optional
-(void)onCubeContainerPanGestureEndWithLessScore;
@end

@interface CubeContainerView : UIView<UIGestureRecognizerDelegate>
//literally
@property (nonatomic)BOOL hasTapOnContainer;

@property (strong,nonatomic)id<CubeContainerDelegate> delegate;

- (id)initWithFrame:(CGRect)frame withSolutionDic:(NSDictionary*)dic andScoreView:(ScoreBoardView*)scoreBoardView;
- (void)giveAHint;
@end
