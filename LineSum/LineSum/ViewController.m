//
//  ViewController.m
//  LineSum
//
//  Created by Lanston Peng on 4/17/14.
//  Copyright (c) 2014 Vtm. All rights reserved.
//

#import "ViewController.h"

#define GRID_WIDTH 4
#define GRID_HEIGHT 4
#define UP_PADDING 10
#define CUBE_WIDTH 80
#define CUBE_LINE_COUNT 4
#define CUBE_COUNT 3

//Game Cube Value
#define CUBE_VALUE_MAX 9
#define CUBE_SELECTED_COLOR 0xFF6B6B

@interface ViewController ()<ScoreTargetDelgate,TimeBarDelegate>

@property (strong,nonatomic)NSArray* sequence;
@property (nonatomic)NSUInteger sum;
@property (strong,nonatomic)NSMutableArray* cubeViews;
@property (strong,nonatomic)NSMutableArray* usedIndexArray;
@property (strong,nonatomic)NSMutableArray* occupiedArray;
@property (strong,nonatomic)NSMutableArray* occupiedCubeViewArray;
@property (strong,nonatomic)UIView* containerView;
@property (strong,nonatomic)CubePath* cubePath;
@property (strong,nonatomic)UIButton* restartBtn;
@property (strong,nonatomic)ScoreBoardView* scoreBoardView;
@property (strong,nonatomic)UILabel* sumLabel;
@property (strong,nonatomic)TimeBar* timeBar;
@property (strong,nonatomic)NSTimer* timeBarTimer;
@property (strong,nonatomic)NSMutableArray* solutionIdxArray;

@property (nonatomic)BOOL hasTapOnContainer;
@property (strong,nonatomic)UIView* hintViewRef;

@property  (strong,nonatomic)UIPanGestureRecognizer* panGesture;
@end


@implementation ViewController
- (NSMutableArray *)solutionIdxArray{
    if(!_solutionIdxArray){
        _solutionIdxArray = [[NSMutableArray alloc]init];
    }
    return  _solutionIdxArray;
}
- (NSMutableArray *)usedIndexArray{
    if(!_usedIndexArray){
        _usedIndexArray = [[NSMutableArray alloc]init];
    }
    return  _usedIndexArray;
}
- (NSMutableArray *)occupiedArray{
    if(!_occupiedArray){
        _occupiedArray = [[NSMutableArray alloc]init];
    }
    return _occupiedArray;
}
- (NSMutableArray *)occupiedCubeViewArray{
    if(!_occupiedCubeViewArray){
        _occupiedCubeViewArray = [[NSMutableArray alloc]init];
    }
    return _occupiedCubeViewArray;
}
-(CubePath*)cubePath{
    if(!_cubePath){
        _cubePath = [[CubePath alloc]init];
    }
    return _cubePath;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    NSDictionary* dic = [Util generateNumbers:CUBE_COUNT];
    self.sequence = [dic objectForKey:@"sequence"];
    self.sum = [(NSNumber*)[dic objectForKey:@"sum"] integerValue];
    [self initGameUI];
    
    //Text Label
    self.sumLabel = [[UILabel alloc]initWithFrame:CGRectMake(20, 50, 120, 40)];
    self.sumLabel.text = [[dic objectForKey:@"sum"] stringValue];
    [self.view addSubview:self.sumLabel];
    
    [self generateGrid:self.sequence];
    [self lineUpSolutionPath:self.sequence];
    
    self.timeBar = [[TimeBar alloc]init];
    self.timeBar.backgroundColor = [Util generateColor];
    [self.view addSubview:self.timeBar];
   
    self.timeBar.delegate =self;
    [self prepareTimer];
    
    //Full Screen
    [[UIApplication sharedApplication]setStatusBarHidden:YES];
   
}
#pragma handle Tap gesture
-(void)handleTap:(UITapGestureRecognizer*)sender{
    self.hasTapOnContainer = YES;
    [self stopBlink];
}
#pragma handle Pan gesture
-(void)handlePan:(UIPanGestureRecognizer *)sender
{
    if(self.hasTapOnContainer){
        self.hasTapOnContainer = YES;
        [self stopBlink];
    }
    //Alert View will trigger pan gesture of such state
    if(sender.state == UIGestureRecognizerStateCancelled){
        return;
    }
    double pointerX = [sender locationInView:self.containerView].x;
    double pointerY = [sender locationInView:self.containerView].y - UP_PADDING;
    
    int x =  pointerX / (GRID_WIDTH * CUBE_WIDTH ) * GRID_WIDTH;
    int y = pointerY / (GRID_HEIGHT * CUBE_WIDTH) * GRID_HEIGHT;
    
    int idx =(x+ 4 * y + 1);
    UIView* currentView =[self.view viewWithTag:idx];
    __weak typeof(self) weakSelf = self;
    CubeEntity* cubeEntity = [[CubeEntity alloc]initWithView:currentView x:x y:y];
    
    //Things to Do
    //record the cube path so that we can change the status while users moving back
    //while it move inside the cube ,prevent it from running the logic again
    //the first time moving into the current view
    if(![self.cubePath isEqualToLastObject:cubeEntity]){
        
        //prevent diagonal line
        if([self isDiagonalLine:x y:y]){
            return;
        }
        int num = [cubeEntity.score intValue];
        if(![self.cubePath containCubePath:cubeEntity]){
            [cubeEntity.cubeView setBackgroundColor:UIColorFromRGB(CUBE_SELECTED_COLOR)];
            [self.cubePath addCubeEntity:cubeEntity];
            [self.scoreBoardView addNum:num];
        }
        //if the view is already in the path,we revert the path
        else{
           [_cubePath revertPathAfterCubeView:cubeEntity executeBlokOnRevertedItem:^(CubeEntity *cubeEntity){
               [cubeEntity.cubeView setBackgroundColor:[Util generateColorWithNum:cubeEntity.score]];
               [weakSelf.scoreBoardView minusNum:[cubeEntity.score intValue]];
           } includingBeginItem:NO];
        }
    }
    else if(sender.state == UIGestureRecognizerStateEnded){
        if([self.scoreBoardView getCurrentState] == LESS){
            CubeEntity* firstEntity = [self.cubePath.cubePathArray firstObject];
           [_cubePath revertPathAfterCubeView:firstEntity executeBlokOnRevertedItem:^(CubeEntity *cubeEntity) {
               [cubeEntity.cubeView setBackgroundColor:[Util generateColorWithNum:cubeEntity.score]];
               [weakSelf.scoreBoardView minusNum:[cubeEntity.score intValue]];
           } includingBeginItem:YES];
           [self.occupiedArray removeAllObjects];
            [self showMessage:@"Nope" withMsg:@"Too Small"];
        }
    }
    
}
- (NSMutableAttributedString*)generateLabelAttributeString:(NSString*)content{
    NSMutableAttributedString* labelAttributeString = [[NSMutableAttributedString alloc]initWithString:content];
    NSRange range = NSMakeRange(0, content.length);
    [labelAttributeString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Apple Color Emoji" size:36] range:range];
    [labelAttributeString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:range];
    return labelAttributeString;
}
- (UIView*)generateCube:(CGRect)frame withNum:(int)currentNum{
    UIView* cubeView = [[UIView alloc]initWithFrame:frame];
    [cubeView setBackgroundColor:[Util generateColorWithNum:[NSString stringWithFormat:@"%d",currentNum]]];
    
    UILabel* numLabel = [[UILabel alloc]initWithFrame:CGRectMake(0,0,CUBE_WIDTH, CUBE_WIDTH)];
    numLabel.attributedText = [self generateLabelAttributeString:[NSString stringWithFormat:@"%d",currentNum]];
    numLabel.textAlignment = NSTextAlignmentCenter;
    
    [numLabel setTag:LUCKY_NUM];
    [cubeView addSubview:numLabel];
    return cubeView;
}
- (void)generateGrid:(NSArray*)sequence{
    int i = 0;
    int randomNumber;
    for(;i< GRID_WIDTH * GRID_HEIGHT; i++){
        randomNumber = arc4random() % (CUBE_VALUE_MAX - 1) + 1;
        UIView* cubeView =[self generateCube:CGRectMake( i * CUBE_WIDTH % (int)IPHONE_SCREEN_WIDTH, UP_PADDING + (i / CUBE_LINE_COUNT) * CUBE_WIDTH, CUBE_WIDTH, CUBE_WIDTH) withNum:randomNumber];
        [cubeView setTag:i+1];
        [self.containerView addSubview:cubeView];
    }
}
- (void)giveAHint{
    if([self.solutionIdxArray count] < 1){
        return;
    }
    
    int idx = [(NSNumber*)[self.solutionIdxArray firstObject] intValue];
    self.hintViewRef =[self.view viewWithTag:idx];
    
    self.hintViewRef.alpha = 1.0f;
    [UIView animateWithDuration:0.6
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut |
     UIViewAnimationOptionRepeat |
     UIViewAnimationOptionAutoreverse |
     UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.hintViewRef.alpha = 0.3f;
                     }
                     completion:^(BOOL finished){
                         // Do nothing
                     }];
}
-(void)stopBlink{
    [UIView animateWithDuration:0.12
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut |
     UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.hintViewRef.alpha = 1.0f;
                     }
                     completion:^(BOOL finished){
                         // Do nothing
                     }];

}
- (void)placeAValideCubeView:(int)x y:(int)y withSequenceIdx:(NSUInteger)index
{
    int idx = [self getIndex:x y:y];
    UIView* currentView =[self.view viewWithTag:idx];
    UILabel* numLabel = (UILabel*)[currentView viewWithTag:LUCKY_NUM];
    NSNumber* number = self.sequence[index];
    [self.solutionIdxArray addObject:[NSNumber numberWithInt:idx]];
    currentView.backgroundColor = [Util generateColorWithNum:[number stringValue]];
    numLabel.attributedText = [self generateLabelAttributeString:[number stringValue]];
}
- (void)lineUpSolutionPath:(NSArray*)sequence
{
    int x = arc4random() % 4;
    int y = arc4random() % 4;
    BOOL hasChanged = NO;
    NSMutableArray* avaiable = [[NSMutableArray alloc]initWithArray:@[@0,@1,@2,@3]];
    NSNumber* deprecated = @-1;
    //[self placeAValideCubeView:x y:y withSequenceIdx:0];
    for(int i = 0;i < [sequence count];i++){
        hasChanged = NO;
        int directionIdx = arc4random() % [avaiable count];
        switch ([avaiable[directionIdx]intValue]) {
            //UP
            case 0:{
                y--;
                hasChanged = YES;
                if(![self isValidCoordinate:x y:y])
                {
                    y++;
                    i--;
                    hasChanged = NO;
                }
                break;
            }
            //DOWN
            case 1:{
                y++;
                hasChanged = YES;
                if(![self isValidCoordinate:x y:y])
                {
                    y--;
                    i--;
                    hasChanged = NO;
                }
                break;
            }
            //RIGHT
            case 2:{
                x++;
                hasChanged = YES;
                if(![self isValidCoordinate:x y:y])
                {
                    x--;
                    i--;
                    hasChanged = NO;
                }
                break;
            }
            //LEFT
            case 3:{
                x--;
                hasChanged = YES;
                if(![self isValidCoordinate:x y:y])
                {
                    x++;
                    i--;
                    hasChanged = NO;
                }
                break;
            }
            default:
                break;
        }
        if(hasChanged){
            if([deprecated intValue] > -1){
                [avaiable addObject:deprecated];
            }
            deprecated = avaiable[directionIdx];
            [avaiable removeObject:avaiable[directionIdx]];
            [self.occupiedArray addObject:@[[NSNumber numberWithInt:x],[NSNumber numberWithInt:y]]];
            [self placeAValideCubeView:x y:y withSequenceIdx:i];
        }
    }
}
- (int)getIndex:(int)x y:(int)y
{
    return x + y * 4 + 1;
}
- (BOOL)isValidCoordinate:(int)x y:(int)y
{
    int boundaryX = 3;
    int boundaryY = 3;
    return (x >= 0 && y>=0 && x<= boundaryX && y<=boundaryY) && ![self isOccupied:x y:y];
}
- (BOOL)isOccupied:(int)x y:(int)y
{
    for(int i = 0 ;i < [self.occupiedArray count]; i++)
    {
        if([self.occupiedArray[i][0] intValue] == x &&[self.occupiedArray[i][1] intValue] == y)
        {
            return YES;
        }
    }
    return NO;
}
//while the user pan too fast on diagonal line ,it would properly cause bug
- (BOOL)isDiagonalLine:(int)x2 y:(int)y2{
    CubeEntity* lastObject = [self.cubePath.cubePathArray lastObject];
    if(!lastObject){
        return NO;
    }
    int y1 = [lastObject.y intValue];
    int x1 = [lastObject.x intValue];
    if(y1 == y2){
        if(x1 == x2 - 1 || x1 == x2 + 1){
            return NO;
        }
    }
    else if(x1 == x2){
        if(y1 == y2 -1 || y1 == y2 + 1){
            return NO;
        }
    }
    return YES;
}
//- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
//    NSLog(@"touch end");
//}
-(void)initGameUI{
    
    self.scoreBoardView = [[ScoreBoardView alloc]initScoreBoradView:(int)_sum
                                                       withDelegate:self];
    
    self.containerView = [[UIView alloc]initWithFrame:CGRectMake(0, 100, IPHONE_SCREEN_WIDTH, IPHONE_SCREEN_HEIGHT)];
    self.restartBtn = [[UIButton alloc]initWithFrame:CGRectMake(200, 50, 100, 40)];
    [self.restartBtn setTitle:@"Restart" forState:UIControlStateNormal];
    self.restartBtn.backgroundColor = [Util generateColor];
    self.scoreBoardView.backgroundColor = [Util generateColor];
    
    [self.view addSubview:self.containerView];
    [self.view addSubview:self.scoreBoardView];
    [self.view addSubview:self.restartBtn];
    
    self.panGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePan:)];
    [self.panGesture setMaximumNumberOfTouches:1];
    UITapGestureRecognizer* restartTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(restartGame)];
    [self.restartBtn addGestureRecognizer:restartTap];
    [self.containerView addGestureRecognizer:self.panGesture];
    UITapGestureRecognizer* containerTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTap:)];
    [self.containerView addGestureRecognizer:containerTap];
}
-(void)restartGame
{
    NSDictionary* dic = [Util generateNumbers:CUBE_COUNT];
    self.sequence = [dic objectForKey:@"sequence"];
    self.sum = [(NSNumber*)[dic objectForKey:@"sum"] integerValue];
    self.sumLabel.text = [[dic objectForKey:@"sum"] stringValue];
    self.scoreBoardView.targetSum = (int)self.sum;
    [self.scoreBoardView resetNum];
    
    [self.containerView removeFromSuperview];
    self.containerView = [[UIView alloc]initWithFrame:CGRectMake(0, 100, IPHONE_SCREEN_WIDTH, IPHONE_SCREEN_HEIGHT)];
    [self.containerView addGestureRecognizer:self.panGesture];
    [self.view addSubview:self.containerView];
    
    [self.occupiedArray removeAllObjects];
    
    [self generateGrid:self.sequence];
    [self lineUpSolutionPath:self.sequence];
    [self.cubePath.cubePathArray removeAllObjects];
    
    [self.timeBarTimer invalidate];
    [self prepareTimer];
    
    [self.solutionIdxArray removeAllObjects];
    self.hasTapOnContainer = NO;
}

-(void)showMessage:(NSString*)title withMsg:(NSString*)msg{
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:title
                                                      message:msg
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
    
    [message show];
}

#pragma ScoreBoard delegate
- (void)onScoreBigger{
    [self showMessage:@"Oops" withMsg:@"Too Big Buddy"];
    self.timeBar.percentage = 1.0;
    [self restartGame];
}
- (void)onScoreEqual{
    //[self showMessage:@"Yep" withMsg:@"You got it"];
    [self.timeBar addProgressByPersentage:0.15f];
    [self restartGame];
}

-(void)prepareTimer{
    self.timeBar.frame = CGRectMake(0, 0, IPHONE_SCREEN_WIDTH * self.timeBar.percentage, 10);
    self.timeBarTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(dropProgress) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop]addTimer:self.timeBarTimer forMode:NSDefaultRunLoopMode];
}

#pragma time bar delegate
-(void)onTimesUp{
    [self.timeBarTimer invalidate];
    [self showMessage:@"Oops" withMsg:@"You ran out of time"];
    self.timeBar.percentage = 1.0;
    [self restartGame];
}

#pragma drop progress timer
-(void)dropProgress
{
    [self.timeBar dropProgressByPersentage:0.01];
    if(self.timeBar.percentage <= 0.98f && !self.hasTapOnContainer){
        self.hasTapOnContainer = YES;
        [self giveAHint];
    }
}
@end
