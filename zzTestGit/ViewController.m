//
//  ViewController.m
//  zzTestGit
//
//  Created by 赵兴隆 on 2018/5/21.
//  Copyright © 2018年 赵兴隆. All rights reserved.
//

#import "ViewController.h"
#import "TestViewController.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //引用
    [TestViewController add];
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
