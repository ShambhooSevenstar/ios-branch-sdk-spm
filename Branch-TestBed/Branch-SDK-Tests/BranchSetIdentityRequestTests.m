//
//  BranchSetIdentityRequestTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/10/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BNCTestCase.h"
#import "BranchSetIdentityRequest.h"
#import "BranchConstants.h"
#import "BNCPreferenceHelper.h"
#import <OCMock/OCMock.h>

static NSString * const IDENTITY_TEST_USER_ID = @"foo_id";

@interface BranchSetIdentityRequestTests : BNCTestCase
@end

@implementation BranchSetIdentityRequestTests

- (void)testRequestBody {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    NSDictionary * const expectedParams = @{
        BRANCH_REQUEST_KEY_DEVELOPER_IDENTITY: IDENTITY_TEST_USER_ID,
        BRANCH_REQUEST_KEY_RANDOMIZED_BUNDLE_TOKEN: preferenceHelper.randomizedBundleToken,
        BRANCH_REQUEST_KEY_RANDOMIZED_DEVICE_TOKEN: preferenceHelper.randomizedDeviceToken,
        BRANCH_REQUEST_KEY_SESSION_ID: preferenceHelper.sessionID
    };

    BranchSetIdentityRequest *request = [[BranchSetIdentityRequest alloc] initWithUserId:IDENTITY_TEST_USER_ID callback:NULL];
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [[serverInterfaceMock expect] postRequest:expectedParams url:[self stringMatchingPattern:BRANCH_REQUEST_ENDPOINT_SET_IDENTITY] key:[OCMArg any] callback:[OCMArg any]];
    
    [request makeRequest:serverInterfaceMock key:nil callback:NULL];
    
    [serverInterfaceMock verify];
}

- (void)testBasicSuccess {
    NSString * const PRE_RESPONSE_USER_IDENTITY = @"foo";
    NSString * const PRE_RESPONSE_IDENTITY = @"foo";
    NSString * const PRE_RESPONSE_USER_URL = @"http://foo";
    NSString * const PRE_RESPONSE_INSTALL_PARAMS = @"{\"foo\":\"bar\"}";
    NSString * const RESPONSE_IDENTITY = @"bar";
    NSString * const RESPONSE_USER_URL = @"http://bar";
    NSString * const RESPONSE_INSTALL_PARAMS = @"{\"bar\":\"foo\"}";
    NSDictionary * const RESPONSE_INSTALL_PARAMS_DICT = @{ @"bar": @"foo" };
    __block NSInteger callbackCount = 0;
    
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    preferenceHelper.userIdentity = PRE_RESPONSE_USER_IDENTITY;
    preferenceHelper.randomizedBundleToken = PRE_RESPONSE_IDENTITY;
    preferenceHelper.userUrl = PRE_RESPONSE_USER_URL;
    preferenceHelper.installParams = PRE_RESPONSE_INSTALL_PARAMS;
    
    BNCServerResponse * const goodResponse = [[BNCServerResponse alloc] init];
    goodResponse.data = @{
        BRANCH_RESPONSE_KEY_RANDOMIZED_BUNDLE_TOKEN: RESPONSE_IDENTITY,
        BRANCH_RESPONSE_KEY_USER_URL: RESPONSE_USER_URL,
        BRANCH_RESPONSE_KEY_INSTALL_PARAMS: RESPONSE_INSTALL_PARAMS
    };
    
    BranchSetIdentityRequest *request = [[BranchSetIdentityRequest alloc] initWithUserId:IDENTITY_TEST_USER_ID callback:^(NSDictionary *params, NSError *error) {
        callbackCount++;
        XCTAssertEqualObjects(params, RESPONSE_INSTALL_PARAMS_DICT);
        XCTAssertNil(error);
    }];
    
    [request processResponse:goodResponse error:nil];
    
    XCTAssertEqual(callbackCount, 1);
    XCTAssertEqualObjects(preferenceHelper.userIdentity, IDENTITY_TEST_USER_ID);
    XCTAssertEqualObjects(preferenceHelper.randomizedBundleToken, RESPONSE_IDENTITY);
    XCTAssertEqualObjects(preferenceHelper.userUrl, RESPONSE_USER_URL);
    XCTAssertEqualObjects(preferenceHelper.installParams, RESPONSE_INSTALL_PARAMS);
}

- (void)testBasicErrorHandling {
    NSError * const TEST_ERROR = [NSError errorWithDomain:@"foo" code:1 userInfo:nil];
    __block NSInteger callbackCount = 0;
    
    BranchSetIdentityRequest *request =
        [[BranchSetIdentityRequest alloc]
            initWithUserId:IDENTITY_TEST_USER_ID
            callback:^(NSDictionary *params, NSError *error) {
                callbackCount++;
                XCTAssert(params != nil && params.count == 0);
                XCTAssertEqual(error, TEST_ERROR);
            }];
    
    [request processResponse:nil error:TEST_ERROR];
    XCTAssertEqual(callbackCount, 1);
}

- (void)testMultipleErrors {
    NSError * const TEST_ERROR = [NSError errorWithDomain:@"foo" code:1 userInfo:nil];
    __block NSInteger callbackCount = 0;
    
    BranchSetIdentityRequest *request =
        [[BranchSetIdentityRequest alloc]
            initWithUserId:IDENTITY_TEST_USER_ID
            callback:^(NSDictionary *params, NSError *error) {
                callbackCount++;
                XCTAssert(params != nil && params.count == 0);
                XCTAssertEqual(error, TEST_ERROR);
            }];

    [request processResponse:nil error:TEST_ERROR];
    [request processResponse:nil error:TEST_ERROR];
    
    XCTAssertEqual(callbackCount, 1);
}

- (void)testErrorFollowedBySuccess {
    NSError * const TEST_ERROR = [NSError errorWithDomain:@"foo" code:1 userInfo:nil];
    NSString * const PRE_RESPONSE_USER_IDENTITY = @"foo";
    NSString * const PRE_RESPONSE_IDENTITY = @"foo";
    NSString * const PRE_RESPONSE_USER_URL = @"http://foo";
    NSString * const PRE_RESPONSE_INSTALL_PARAMS = @"{\"foo\":\"bar\"}";
    NSString * const RESPONSE_IDENTITY = @"bar";
    NSString * const RESPONSE_USER_URL = @"http://bar";
    NSString * const RESPONSE_INSTALL_PARAMS = @"{\"bar\":\"foo\"}";
    __block NSInteger callbackCount = 0;
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    preferenceHelper.userIdentity = PRE_RESPONSE_USER_IDENTITY;
    preferenceHelper.randomizedBundleToken = PRE_RESPONSE_IDENTITY;
    preferenceHelper.userUrl = PRE_RESPONSE_USER_URL;
    preferenceHelper.installParams = PRE_RESPONSE_INSTALL_PARAMS;

    BNCServerResponse * const goodResponse = [[BNCServerResponse alloc] init];
    goodResponse.data = @{
        BRANCH_RESPONSE_KEY_RANDOMIZED_BUNDLE_TOKEN: RESPONSE_IDENTITY,
        BRANCH_RESPONSE_KEY_USER_URL: RESPONSE_USER_URL,
        BRANCH_RESPONSE_KEY_INSTALL_PARAMS: RESPONSE_INSTALL_PARAMS
    };
    
    BranchSetIdentityRequest *request =
        [[BranchSetIdentityRequest alloc]
            initWithUserId:IDENTITY_TEST_USER_ID
            callback:^(NSDictionary *params, NSError *error) {
                callbackCount++;
                XCTAssert(params != nil && params.count == 0);
                XCTAssertEqual(error, TEST_ERROR);
            }];

    [request processResponse:nil error:TEST_ERROR];
    [request processResponse:goodResponse error:nil];
    
    XCTAssertEqual(callbackCount, 1); // callback should have only been called once, but preferences should be updated
    XCTAssertEqualObjects(preferenceHelper.userIdentity, IDENTITY_TEST_USER_ID);
    XCTAssertEqualObjects(preferenceHelper.randomizedBundleToken, RESPONSE_IDENTITY);
    XCTAssertEqualObjects(preferenceHelper.userUrl, RESPONSE_USER_URL);
    XCTAssertEqualObjects(preferenceHelper.installParams, RESPONSE_INSTALL_PARAMS);
}


- (void)testEmptyResponseFieldsAfterSetIdentity {
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    
    __block NSInteger callbackCount = 0;
    
    BranchSetIdentityRequest *request = [[BranchSetIdentityRequest alloc] initWithUserId:IDENTITY_TEST_USER_ID callback:^(NSDictionary *params, NSError *error) {
        callbackCount++;
        XCTAssertNil(error);
    }];
    
    response.data = @{};
    [request processResponse:response error:nil];
    
    XCTAssertNotNil(preferenceHelper.randomizedDeviceToken);
    XCTAssertNotNil(preferenceHelper.userUrl);
    XCTAssertNotNil(preferenceHelper.sessionID);
    XCTAssertNotNil(preferenceHelper.randomizedBundleToken);
}

#pragma mark -  setIdentity Tests
- (void)testSetIdentityWithCallback {
    Branch *branch = [Branch getInstance];
    [branch logoutWithCallback:^(BOOL changed, NSError * _Nullable error) {
        BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper new];

        XCTestExpectation *expectation = [self expectationWithDescription:@"setIdentity callback is called"];
        
        [branch setIdentity:@"testUserIdWithCallback" withCallback:^(NSDictionary *params, NSError *error) {
            XCTAssertEqualObjects(@"testUserIdWithCallback", preferenceHelper.userIdentity);
            [expectation fulfill];
        }];
        
        [self waitForExpectationsWithTimeout:5 handler:nil];
    }];
}

- (void)testSetIdentityWithNilUserId {
    Branch *branch = [Branch getInstance];
    [branch logoutWithCallback:^(BOOL changed, NSError * _Nullable error) {
        BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper new];

        XCTestExpectation *expectation = [self expectationWithDescription:@"setIdentityWithNil callback is called"];
        
        [branch setIdentity:nil withCallback:^(NSDictionary *params, NSError *error) {
            XCTAssertNil(preferenceHelper.userIdentity);
            [expectation fulfill];
        }];
        
        [self waitForExpectationsWithTimeout:5 handler:nil];
    }];
    

}

- (void)testSetIdentityWithUserId {
    Branch *branch = [Branch getInstance];
    [branch logoutWithCallback:^(BOOL changed, NSError * _Nullable error) {
        BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper new];

        NSString *testUserId = @"testUserId";
        [branch setIdentity:testUserId withCallback:nil];

        XCTAssertEqualObjects(@"testUserId", preferenceHelper.userIdentity);
    }];

}

@end
