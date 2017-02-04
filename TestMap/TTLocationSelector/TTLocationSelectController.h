//
//  TTLocationSelectController.h
//  TestMap
//
//  Created by tanson on 2017/2/2.
//  Copyright © 2017年 chatchat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MAMapKit/MAMapKit.h>
#import "TTNearyPOIView.h"

typedef void (^TTLocalSelectorSendHandel)(TTLocationModel * mdoel);

@interface TTLocationSelectController : UIViewController

@property (nonatomic,copy) TTLocalSelectorSendHandel sendBlock;
@end
