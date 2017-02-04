//
//  ViewController.m
//  TestMap
//
//  Created by tanson on 2017/1/31.
//  Copyright © 2017年 chatchat. All rights reserved.
//

#import "ViewController.h"
#import "TTLocationSelectController.h"
#import "TTGaoDeMapViewController.h"

@interface ViewController ()
@property (nonatomic,strong) TTLocationModel * model;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (IBAction)onButton:(id)sender {

    TTLocationSelectController *vc = [[TTLocationSelectController alloc] initWithNibName:@"TTLocationSelectController" bundle:nil];
    vc.sendBlock = ^(TTLocationModel *m){
        NSLog(@"%@",m);
        self.model = m;
    };
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)onMap:(id)sender {
    TTGaoDeMapViewController * map = [[TTGaoDeMapViewController alloc] initWithNibName:@"TTGaoDeMapViewController" bundle:nil];
    map.model = self.model;
    [self.navigationController pushViewController:map animated:YES];
}


@end
