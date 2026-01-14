//
//  _JSNestedScrollViewMediator.m
//  JSNestedScroll
//
//  Created by jiasong on 2022/6/1.
//

#import "_JSNestedScrollViewMediator.h"
#import "JSCoreMacroMethod.h"

@interface _JSNestedScrollViewMediator ()

@property (nonatomic, assign, readwrite) BOOL isHooked;

@end

@implementation _JSNestedScrollViewMediator

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static _JSNestedScrollViewMediator *instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    return [self shared];
}

- (void)onceHookAdjustContentOffset:(void(^)(UIScrollView *scrollView, BOOL isExecuted))adjustContentOffset
                   setContentOffset:(void(^)(UIScrollView *scrollView, CGPoint offset, BOOL animated))setContentOffset {
    if (self.isHooked) {
        return;
    }
    self.isHooked = YES;
    
    NSString *adjustContentOffsetName = [NSString stringWithFormat:@"_%@%@%@", @"adjust", @"ContentOffset", @"IfNecessary"];
    JSRuntimeOverrideImplementation(UIScrollView.class, NSSelectorFromString(adjustContentOffsetName), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
        return ^(UIScrollView *selfObject) {
            
            adjustContentOffset(selfObject, NO);
            
            // call super
            void (*originSelectorIMP)(id, SEL);
            originSelectorIMP = (void (*)(id, SEL))originalIMPProvider();
            originSelectorIMP(selfObject, originCMD);
            
            adjustContentOffset(selfObject, YES);
        };
    });
    JSRuntimeOverrideImplementation(UIScrollView.class, @selector(setContentOffset:animated:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
        return ^(UIScrollView *selfObject, CGPoint contentOffset, BOOL animated) {
            
            // call super
            void (*originSelectorIMP)(id, SEL, CGPoint, BOOL);
            originSelectorIMP = (void (*)(id, SEL, CGPoint, BOOL))originalIMPProvider();
            originSelectorIMP(selfObject, originCMD, contentOffset, animated);
            
            setContentOffset(selfObject, contentOffset, animated);
        };
    });
    if (@available(iOS 26.2, *)) {
        /// 实测iOS 26.2以上，UICollectionView.setContentOffset内部不会调用setContentOffset:animated:
        JSRuntimeOverrideImplementation(UICollectionView.class, @selector(setContentOffset:animated:), ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
            return ^(UICollectionView *selfObject, CGPoint contentOffset, BOOL animated) {
                
                // call super
                void (*originSelectorIMP)(id, SEL, CGPoint, BOOL);
                originSelectorIMP = (void (*)(id, SEL, CGPoint, BOOL))originalIMPProvider();
                originSelectorIMP(selfObject, originCMD, contentOffset, animated);
                
                setContentOffset(selfObject, contentOffset, animated);
            };
        });
    }
}

@end
