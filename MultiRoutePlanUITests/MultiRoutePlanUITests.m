//
//  MultiRoutePlanUITests.m
//  MultiRoutePlanUITests
//
//  Created by liubo on 2017/1/10.
//  Copyright © 2017年 Amap. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface MultiRoutePlanUITests : XCTestCase

@end

@implementation MultiRoutePlanUITests

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    [[[XCUIApplication alloc] init] launch];
    
    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCalculateRoute {
    
    XCUIApplication *app = [[XCUIApplication alloc] init];
    XCUIElement *element = [[[[[[app.otherElements containingType:XCUIElementTypeNavigationBar identifier:@"多路径规划"] childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther] elementBoundByIndex:2];
    
    //判断算路结果
    XCUIElementQuery *nilInfoModel = [element.staticTexts containingPredicate:[NSPredicate predicateWithFormat:@"%K CONTAINS[cd] %@", @"label", @"请在上方进行算路"]];
    NSPredicate *nilInfoModelPredicate = [NSPredicate predicateWithFormat:@"count <= 0"];
    __block XCTestExpectation *expectation = [self expectationForPredicate:nilInfoModelPredicate evaluatedWithObject:nilInfoModel handler:nil];
    [self waitForExpectationsWithTimeout:25 handler:^(NSError * _Nullable error) {
        expectation = nil;
        
        if (error)
        {
            XCTAssert(@"expectation error");
        }
    }];
    
    XCUIElementQuery *allInfoViewButtons = [app.buttons containingType:XCUIElementTypeAny identifier:@"RouteInfoViewButton"];
    NSInteger infoViewButtonCount = allInfoViewButtons.count;
    
    XCUIElement *infoViewButton1 = [allInfoViewButtons elementBoundByIndex:(infoViewButtonCount - 1)];
    XCUIElement *infoViewButton2 = [allInfoViewButtons elementBoundByIndex:0];
    
    //切换路径
    sleep(1);
    [infoViewButton1 tap];
    
    sleep(1);
    [infoViewButton2 tap];
    
    //重新规划路径
    sleep(1);
    [app.buttons[@"躲避拥堵"] tap];
    [app.buttons[@"不走高速"] tap];
    [app.buttons[@"路径规划"] tap];
    
    sleep(5);
    allInfoViewButtons = [app.buttons containingType:XCUIElementTypeAny identifier:@"RouteInfoViewButton"];
    infoViewButtonCount = allInfoViewButtons.count;
    
    XCUIElement *infoViewButton3 = [allInfoViewButtons elementBoundByIndex:(infoViewButtonCount - 1)];
    XCUIElement *infoViewButton4 = [allInfoViewButtons elementBoundByIndex:0];
    
    //切换路径
    sleep(1);
    [infoViewButton3 tap];
    
    sleep(1);
    [infoViewButton4 tap];
    
    //进行导航
    sleep(1);
    [app.buttons[@"开始导航"] tap];
    
    sleep(5);
    XCUIElement *defaultNaviFooterIconCloseButton = app.buttons[@"default navi footer icon close"];
    [defaultNaviFooterIconCloseButton tap];
    
    sleep(1);
}

@end
