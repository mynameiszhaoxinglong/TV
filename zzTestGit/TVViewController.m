//
//  ViewController.m
//  AVPlayerDemo
//
//  Created by 赵兴隆 on 18/04/20.
//  Copyright © 2018年 HD. All rights reserved.
//

#import "TVViewController.h"
#import "Masonry.h"
#import <AVFoundation/AVFoundation.h>

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@interface TVViewController ()

@property (strong, nonatomic) UIView *backView;
@property (nonatomic,strong) AVPlayer *player;
@property (nonatomic,strong) AVPlayerItem *playerItem;
@property (nonatomic,strong) AVPlayerLayer *playerLayer;
//底部BottmView
@property (nonatomic,strong) UIView *bottomView;
@property (nonatomic,strong) UIButton *playButton;
@property (nonatomic,strong) UIButton *fullScreenButton;
@property (nonatomic,strong) UIProgressView *progressView;
@property (nonatomic,strong) UISlider *slider;
@property (nonatomic,strong) UILabel *nowLabel;
@property (nonatomic,strong) UILabel *remainLabel;
//顶部TopView
@property (nonatomic,strong) UIView *topView;
@property (nonatomic,strong) UIButton *topBtn;
@property (nonatomic,strong) UILabel *topLabel;
//是否全屏
@property (nonatomic,assign) BOOL isFullScreen;
//自动消失定时器
@property (nonatomic,strong) NSTimer *autoDismissTimer;
@property (nonatomic,assign) BOOL isDragSlider;

@end
static BOOL isSelect = 0;
@implementation TVViewController
//隐藏状态栏
- (BOOL)prefersStatusBarHidden {
    return YES;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    isSelect = 1;
    [self setupUI];
    [self fullScreenAction];
}

- (void)setupUI{
    
    //APP运行状态通知，将要被挂起
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterBackground:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    // app进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterPlayground:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    self.backView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight)];
    self.backView.backgroundColor = [UIColor blackColor];//
    [self.view addSubview:self.backView];
    
    // 初始化播放器

    if (_url.length > 0) {
        self.playerItem = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:self.url]];
    } else {
         self.playerItem = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:@"http://flv2.bn.netease.com/videolib3/1608/30/zPuaL7429/SD/zPuaL7429-mobile.mp4"]];
    }
    
    self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    _playerLayer.frame = self.backView.bounds;
    [self.backView.layer insertSublayer:self.playerLayer atIndex:0];
    
    // 监听播放器状态变化
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    // 监听缓存大小
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
    //添加手势动作,隐藏下面的进度条
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
    [self.backView addGestureRecognizer:tap];
    
    // 布局顶部功能栏
    self.topView = [[UIView alloc] init];
    self.topView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    [self.backView addSubview:self.topView];
    [self.topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.backView).with.offset(0);
        make.right.equalTo(self.backView).with.offset(0);
        make.top.equalTo(self.backView).with.offset(0);
        make.height.mas_equalTo(30);
    }];
    
    //顶部返回按钮
    self.topBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.topView addSubview:self.topBtn];
    [self.topBtn setImage:[UIImage imageNamed:@"bac.png"] forState:UIControlStateNormal];
    
    [self.topBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topView).with.offset(0);
        make.left.equalTo(self.topView).with.offset(2);
        make.height.mas_equalTo(30);
        make.width.mas_equalTo(60);
    }];
    
    [self.topBtn addTarget:self action:@selector(backAction:) forControlEvents:UIControlEventTouchUpInside];
    
    //布局顶部title
    self.topLabel = [[UILabel alloc] init];
    self.topLabel.textColor = [UIColor whiteColor];
    self.topLabel.font = [UIFont systemFontOfSize:15];
    self.topLabel.textAlignment = NSTextAlignmentCenter;
    if (_content.length>0) {
        self.topLabel.text = _content;//title
    } else {
        self.topLabel.text = @"TV";
    }
    
    [self.topView addSubview:self.topLabel];
    [self.topLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.topView).with.offset(25);
        make.right.equalTo(self.topView).with.offset(-25);
        make.top.equalTo(self.topView).with.offset(0);
        make.height.mas_equalTo(30);
    }];
    
    // 布局底部功能栏
    self.bottomView = [[UIView alloc] init];
    self.bottomView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    [self.backView addSubview:self.bottomView];
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.backView).with.offset(0);
        make.right.equalTo(self.backView).with.offset(0);
        make.bottom.equalTo(self.backView).with.offset(0);
        make.height.mas_equalTo(30);
    }];
    
    // 播放或暂停
    self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.playButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    self.playButton.showsTouchWhenHighlighted = YES;
    [self.bottomView addSubview:self.playButton];
    [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomView).with.offset(5);
        make.centerY.equalTo(self.bottomView);
        make.size.mas_equalTo(CGSizeMake(30, 30));
    }];
    //播放
    [self.playButton addTarget:self action:@selector(pauseOrPlay:) forControlEvents:UIControlEventTouchUpInside];
    
    // 底部全屏按钮
    self.fullScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.fullScreenButton setImage:[UIImage imageNamed:@"fullscreen"] forState:UIControlStateNormal];
    self.fullScreenButton.showsTouchWhenHighlighted = YES;
    [self.bottomView addSubview:self.fullScreenButton];
    [self.fullScreenButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.bottomView).with.offset(-5);
        make.centerY.equalTo(self.bottomView);
        make.size.mas_equalTo(CGSizeMake(30, 30));
    }];
    //点击全屏
    [self.fullScreenButton addTarget:self action:@selector(clickFullScreen:) forControlEvents:UIControlEventTouchUpInside];
    
    // 底部进度条
    self.slider = [[UISlider alloc] init];
    self.slider.minimumValue = 0.0;
    self.slider.minimumTrackTintColor = [UIColor greenColor];
    self.slider.maximumTrackTintColor = [UIColor clearColor];
    self.slider.value = 0.0;
    [self.slider setThumbImage:[UIImage imageNamed:@"dot"] forState:UIControlStateNormal];
    [self.bottomView addSubview:self.slider];
    [self.slider mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.left.equalTo(self.bottomView).with.offset(45);
        make.right.equalTo(self.bottomView).with.offset(-45);
        make.centerY.equalTo(self.bottomView);
        
    }];
    [self.slider addTarget:self action:@selector(sliderDragValueChange:) forControlEvents:UIControlEventValueChanged];
    [self.slider addTarget:self action:@selector(sliderTapValueChange:) forControlEvents:UIControlEventTouchUpInside];
    
    UITapGestureRecognizer *tapSlider = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchSlider:)];
    [self.slider addGestureRecognizer:tapSlider];
    [self.bottomView addSubview:self.slider];
    
    // 底部缓存进度条
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.progressTintColor = [UIColor blueColor];
    self.progressView.trackTintColor = [UIColor lightGrayColor];
    [self.bottomView addSubview:self.progressView];
    [self.progressView setProgress:0.0 animated:NO];
    
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.slider).with.offset(0);
        make.right.equalTo(self.slider);
        make.height.mas_equalTo(2);
        make.centerY.equalTo(self.slider).with.offset(1);
    }];
    [self.bottomView sendSubviewToBack:self.progressView];
    
    // 底部左侧时间轴
    self.nowLabel = [[UILabel alloc] init];
    self.nowLabel.textColor = [UIColor whiteColor];
    self.nowLabel.font = [UIFont systemFontOfSize:13];
    self.nowLabel.textAlignment = NSTextAlignmentLeft;
    [self.bottomView addSubview:self.nowLabel];
    [self.nowLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.slider.mas_left).with.offset(0);
        make.top.equalTo(self.slider.mas_bottom).with.offset(0);
        make.size.mas_equalTo(CGSizeMake(100, 20));
    }];
    
    // 底部右侧时间轴
    self.remainLabel = [[UILabel alloc] init];
    self.remainLabel.textColor = [UIColor whiteColor];
    self.remainLabel.font = [UIFont systemFontOfSize:13];
    self.remainLabel.textAlignment = NSTextAlignmentRight;
    [self.bottomView addSubview:self.remainLabel];
    [self.remainLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.slider.mas_right).with.offset(0);
        make.top.equalTo(self.slider.mas_bottom).with.offset(0);
        make.size.mas_equalTo(CGSizeMake(100, 20));
    }];
   
    [self.player play];
}

#pragma mark - 暂停或者播放
- (void)pauseOrPlay:(UIButton *)sender{
    
//    if (self.player.rate != 1)
//    {
//        [sender setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
//
//        [self.player play];
//    }
//    else
//    {
//        [sender setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
//        [self.player pause];
//    }
    
    if (isSelect == 1) {
        [sender setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
        [self.player pause];
        isSelect = 0;
    } else {
        
        [sender setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
        [self.player play];
        isSelect = 1;
    }
}
#pragma mark - APP活动通知
- (void)appDidEnterBackground:(NSNotification *)note{
    //将要挂起，停止播放
    [self.player pause];
    isSelect = YES;
}
- (void)appDidEnterPlayground:(NSNotification *)note{
    //继续播放
    [self.player play];
    if (isSelect == 1) {
        [self.playButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
        [self.player pause];
        isSelect = 0;
    } else {
        
        [self.playButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
        [self.player play];
        isSelect = 1;
    }
}
- (void)fullScreenAction {

    [self.playButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    if (!self.isFullScreen)
    {
        [self toFullScreenWithInterfaceOrientation:UIInterfaceOrientationLandscapeRight];
        [self.fullScreenButton setImage:[UIImage imageNamed:@"nonfullscreen@3x"] forState:UIControlStateNormal];
    }
    else
    {
        [self toSmallScreen];
        [self.fullScreenButton setImage:[UIImage imageNamed:@"fullscreen@3x"] forState:UIControlStateNormal];
    }
    self.isFullScreen = !self.isFullScreen;
}
#pragma mark - 点击全屏按钮
- (void)clickFullScreen:(UIButton *)button{
    
    if (!self.isFullScreen)
    {
        [self toFullScreenWithInterfaceOrientation:UIInterfaceOrientationLandscapeRight];
        [self.fullScreenButton setImage:[UIImage imageNamed:@"nonfullscreen@3x"] forState:UIControlStateNormal];
    }
    else
    {
        [self toSmallScreen];
        [self.fullScreenButton setImage:[UIImage imageNamed:@"fullscreen@3x"] forState:UIControlStateNormal];
    }
    self.isFullScreen = !self.isFullScreen;
    
}
#pragma mark - 显示全屏
-(void)toFullScreenWithInterfaceOrientation:(UIInterfaceOrientation )interfaceOrientation{
    // 先移除之前的
    [self.backView removeFromSuperview];
    // 初始化
    self.backView.transform = CGAffineTransformIdentity;
    if (interfaceOrientation==UIInterfaceOrientationLandscapeLeft) {
        self.backView.transform = CGAffineTransformMakeRotation(-M_PI_2);
    }else if(interfaceOrientation==UIInterfaceOrientationLandscapeRight){
        self.backView.transform = CGAffineTransformMakeRotation(M_PI_2);
    }
    // BackView 全屏
    self.backView.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
    // layer的方向宽和高对调
    self.playerLayer.frame = CGRectMake(0, 0, kScreenHeight, kScreenWidth);
    
    [self.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(50);
        make.top.mas_equalTo(kScreenWidth-50);
        make.left.equalTo(self.backView).with.offset(0);
        make.width.mas_equalTo(kScreenHeight);
    }];
    
    [self.topView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(30);
        make.top.mas_equalTo(0);
        make.left.equalTo(self.backView).with.offset(0);
        make.width.mas_equalTo(kScreenHeight);
    }];
    
    [self.nowLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.slider.mas_left).with.offset(0);
        make.top.equalTo(self.slider.mas_bottom).with.offset(0);
        make.size.mas_equalTo(CGSizeMake(100, 20));
    }];
    
    [self.remainLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.slider.mas_right).with.offset(0);
        make.top.equalTo(self.slider.mas_bottom).with.offset(0);
        make.size.mas_equalTo(CGSizeMake(100, 20));
    }];
    
    // 加到window上面
//    [[UIApplication sharedApplication].keyWindow addSubview:self.backView];
    
    [self.view addSubview:self.backView];
    
}
#pragma mark - 缩小全屏
-(void)toSmallScreen{
    // 先移除
    [self.backView removeFromSuperview];
    
    __weak typeof(self)weakSelf = self;
    [UIView animateWithDuration:0.5f animations:^{
        weakSelf.backView.transform = CGAffineTransformIdentity;
        weakSelf.backView.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);// /2.5
        weakSelf.playerLayer.frame =  weakSelf.backView.bounds;
        [weakSelf.view addSubview:weakSelf.backView];
        
        [self.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(weakSelf.backView).with.offset(0);
            make.right.equalTo(weakSelf.backView).with.offset(0);
            make.height.mas_equalTo(50);
            make.bottom.equalTo(weakSelf.backView).with.offset(0);
        }];
        
        [self.topView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(weakSelf.backView).with.offset(0);
            make.right.equalTo(weakSelf.backView).with.offset(0);
            make.height.mas_equalTo(50);
            make.top.equalTo(weakSelf.backView).with.offset(0);
        }];
    }completion:^(BOOL finished) {
        
    }];
    
}

#pragma mark - 单击手势
- (void)singleTap:(UITapGestureRecognizer *)tap{
    
    [UIView animateWithDuration:1.0 animations:^{
        if (self.bottomView.alpha == 1)
        {
            self.bottomView.alpha = 0;
        }
        else if (self.bottomView.alpha == 0)
        {
            self.bottomView.alpha = 1;
        }
        
        //  返回按钮
        if (self.topView.alpha == 1) {
            self.topView.alpha = 0;
        } else if (self.topView.alpha == 0) {
            self.topView.alpha = 1;
        }
    }];
}

#pragma mark - slider的更改
// 不更新视频进度
- (void)sliderDragValueChange:(UISlider *)slider
{
    self.isDragSlider = YES;
}
// 点击调用  或者 拖拽完毕的时候调用
- (void)sliderTapValueChange:(UISlider *)slider
{
    self.isDragSlider = NO;
    // 直接用秒来获取CMTime
    [self.player seekToTime:CMTimeMakeWithSeconds(slider.value, self.playerItem.currentTime.timescale)];
}

// 点击Slider
- (void)touchSlider:(UITapGestureRecognizer *)tap
{
    // 根据点击的坐标计算对应的比例
    CGPoint touch = [tap locationInView:self.slider];
    CGFloat scale = touch.x / self.slider.bounds.size.width;
    self.slider.value = CMTimeGetSeconds(self.playerItem.duration) * scale;
    [self.player seekToTime:CMTimeMakeWithSeconds(self.slider.value, self.playerItem.currentTime.timescale)];
    if (self.player.rate != 1)
    {
        [self.playButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
        [self.player play];
    }
}


// 监听播放器的变化属性
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"status"])
    {
        AVPlayerItemStatus statues = [change[NSKeyValueChangeNewKey] integerValue];
        switch (statues) {
            case AVPlayerItemStatusReadyToPlay:
                self.slider.maximumValue = CMTimeGetSeconds(self.playerItem.duration);
                [self initTimer];
                // 自动隐藏底栏
                if (!self.autoDismissTimer)
                {
                    self.autoDismissTimer = [NSTimer timerWithTimeInterval:8.0 target:self selector:@selector(autoDismissView:) userInfo:nil repeats:YES];
                    [[NSRunLoop currentRunLoop] addTimer:self.autoDismissTimer forMode:NSDefaultRunLoopMode];
                }
                break;
            case AVPlayerItemStatusUnknown:
                
                break;
            case AVPlayerItemStatusFailed:
                
                break;
                
            default:
                break;
        }
    }
    // 监听缓存进度的属性
    else if ([keyPath isEqualToString:@"loadedTimeRanges"])
    {
        // 计算缓存进度
        NSTimeInterval timeInterval = [self availableDuration];
        // 获取总长度
        CMTime duration = self.playerItem.duration;
        
        CGFloat durationTime = CMTimeGetSeconds(duration);
        // 监听到了给进度条赋值
        [self.progressView setProgress:timeInterval / durationTime animated:NO];
    }
    
    
}

//调用plaer进行UI更新
- (void)initTimer
{
    //player的定时器
    __weak typeof(self)weakSelf = self;
    // 每秒更新一次UI Slider
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        //当前时间
        CGFloat nowTime = CMTimeGetSeconds(weakSelf.playerItem.currentTime);
        //总时间
        CGFloat duration = CMTimeGetSeconds(weakSelf.playerItem.duration);
        //sec 转换成时间点
        weakSelf.nowLabel.text = [weakSelf convertToTime:nowTime];
        weakSelf.remainLabel.text = [weakSelf convertToTime:(duration - nowTime)];
        //不是拖拽中的话更新UI
        if (!weakSelf.isDragSlider)
        {
            weakSelf.slider.value = CMTimeGetSeconds(weakSelf.playerItem.currentTime);
        }
        
    }];
}
//自动隐藏底部功能栏
- (void)autoDismissView:(NSTimer *)timer{
    
    if (self.player.rate == 1)
    {
        [UIView animateWithDuration:2.0 animations:^{
            
            self.bottomView.alpha = 0;
            
        }];
        
        //顶部View
        [UIView animateWithDuration:2.0 animations:^{
            self.topView.alpha = 0;
        }];
    }
}

//计算缓冲进度
- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [self.playerItem loadedTimeRanges];
    //获取缓冲区域
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];
    //开始的点
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    //已缓存的时间点
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    //计算缓冲总进度
    NSTimeInterval result = startSeconds + durationSeconds;
    return result;
}

- (NSString *)convertToTime:(CGFloat)time
{
    // 初始化格式对象
    NSDateFormatter *fotmmatter = [[NSDateFormatter alloc] init];
    // 根据是否大于1H，进行格式赋值
    if (time >= 3600)
    {
        [fotmmatter setDateFormat:@"HH:mm:ss"];
    }
    else
    {
        [fotmmatter setDateFormat:@"mm:ss"];
    }
    // 秒数转换成NSDate类型
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
    // date转字符串
    return [fotmmatter stringFromDate:date];
}
#pragma mark---移除通知----
-(void)removeNsnotification{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillResignActiveNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
   
}
#pragma mark---移除观察者--
-(void)removeObserver{
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
//    [[NSNotificationCenter defaultCenter]removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
}
- (void)backAction:(UIButton *)sender {
    [self.player pause];
    if (self.player) {
        self.player = nil;
        self.playerLayer = nil;
        self.backView = nil;
    }
    //去除动画
    [self.navigationController popViewControllerAnimated:NO];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    self.navigationController.navigationBar.hidden = YES;
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:YES];
    [self.player pause];
    [self removeNsnotification];
    [self removeObserver];
    
    //回到竖屏
    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIInterfaceOrientationPortrait] forKey:@"orientation"];
    //重置状态条
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:NO];
    
    [self.playerLayer removeFromSuperlayer];
    
    if (self.player) {
        self.player = nil;
        self.playerLayer = nil;
        self.backView = nil;
    }
    self.navigationController.navigationBar.hidden = NO;
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:YES];
    self.navigationController.navigationBar.hidden = NO;
}
@end
