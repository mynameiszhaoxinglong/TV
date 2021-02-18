//
//  ViewController.m
//  zzTestGit
//
//  Created by 赵兴隆 on 2018/5/21.
//  Copyright © 2018年 赵兴隆. All rights reserved.
//

#import "ViewController.h"
#import "TestViewController.h"
#import "TVViewController.h"
@interface ViewController ()
- (IBAction)playerToPlay:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //引用
    [TestViewController add];
    
    NSLog(@"git的初次使用");
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)playerToPlay:(id)sender {
    TVViewController *vc = [TVViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

//2021
- (void)svnTest {
    NSLog(@"2021-SVN 14.0");
}

@end
