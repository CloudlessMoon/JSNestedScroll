//
//  _JSNestedScrollViewMediator.h
//  JSNestedScroll
//
//  Created by jiasong on 2022/6/1.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface _JSNestedScrollViewMediator : NSObject

@property (class, nonatomic, readonly) _JSNestedScrollViewMediator *shared;

@property (nonatomic, assign, readonly) BOOL isHooked;

- (instancetype)init NS_UNAVAILABLE;

- (void)onceHookAdjustedContentInset:(void(^)(UIScrollView *scrollView))adjustedContentInset
                 adjustContentOffset:(void(^)(UIScrollView *scrollView, BOOL isExecuted))adjustContentOffset
                    setContentOffset:(void(^)(UIScrollView *scrollView, CGPoint offset, BOOL animated))setContentOffset NS_SWIFT_NAME(onceHook(adjustedContentInset:adjustContentOffset:setContentOffset:));

@end

NS_ASSUME_NONNULL_END
