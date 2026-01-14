//
//  NestedScrollView.swift
//  JSNestedScroll
//
//  Created by jiasong on 2022/5/31.
//

import UIKit
import JSCoreKit

@objc(JSNestedScrollView)
open class NestedScrollView: UIScrollView {
    
    @objc public static let automaticDimension: CGFloat = -1
    
    @objc public var headerView: (UIView & NestedScrollViewScrollSubview)? {
        didSet {
            self.addSubview(self.headerView, oldView: oldValue)
        }
    }
    
    @objc public var middleView: (UIView & NestedScrollViewSupplementarySubview)? {
        didSet {
            self.addSubview(self.middleView, oldView: oldValue)
        }
    }
    
    @objc public var floatingView: (UIView & NestedScrollViewSupplementarySubview)? {
        didSet {
            self.addSubview(self.floatingView, oldView: oldValue)
        }
    }
    
    @objc public var floatingOffset: CGFloat = 0 {
        didSet {
            guard oldValue != self.floatingOffset else {
                return
            }
            
            self.updateLayout()
        }
    }
    
    @objc dynamic public private(set) var isFloating: Bool = false
    
    @objc public var contentView: (UIView & NestedScrollViewScrollSubview)? {
        didSet {
            self.addSubview(self.contentView, oldView: oldValue)
        }
    }
    
    private lazy var containerView: UIView = {
        return UIView()
    }()
    
    private lazy var scrollSubviewDidScrollHandler: NestedScrollDidScrollHandler = {
        return { [weak self] _ in
            guard let self = self else { return }
            self.handleDidScoll()
        }
    }()
    
    private var didScrollCancellable: JSNotificationCancellable?
    
    private var boundsSize: CGSize = .zero
    private var isNeedsLayout: Bool = true
    
    @objc public init() {
        super.init(frame: .zero)
        self.didInitialize()
    }
    
    @available(*, unavailable, message: "use init()")
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func didInitialize() {
        self.contentInsetAdjustmentBehavior = .never
        self.alwaysBounceHorizontal = false
        self.alwaysBounceVertical = true
        self.bounces = true
        self.contentInset = .zero
        if #available(iOS 26.0, *) {
            self.topEdgeEffect.isHidden = true
            self.leftEdgeEffect.isHidden = true
            self.bottomEdgeEffect.isHidden = true
            self.rightEdgeEffect.isHidden = true
        }
        
        self.addSubview(self.containerView)
        
        self.didScrollCancellable = self.js_addDidScrollSubscriber {
            guard let scrollView = $0 as? NestedScrollView else {
                return
            }
            scrollView.handleDidScoll()
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        let bounds = CGRect(
            x: 0.0,
            y: 0.0,
            width: self.bounds.width - self.adjustedContentInset.jsc.horizontal,
            height: self.bounds.height
        )
        if self.isNeedsLayout || self.boundsSize.jsc.estimated() != bounds.size.jsc.estimated() {
            self.isNeedsLayout = false
            self.boundsSize = bounds.size
            
            let headerHeight = {
                var height = self.calculateHeight(for: self.headerView)
                if self.headerScrollView != nil {
                    height = min(height, bounds.height)
                }
                return height
            }()
            self.headerView?.frame = CGRect(
                x: bounds.minX,
                y: bounds.minY,
                width: bounds.width,
                height: headerHeight
            )
            
            let middleHeight = self.calculateHeight(for: self.middleView)
            self.middleView?.frame = CGRect(
                x: bounds.minX,
                y: bounds.minY + headerHeight,
                width: bounds.width,
                height: middleHeight
            )
            
            let floatingHeight = self.calculateHeight(for: self.floatingView)
            self.floatingView?.js_frameApplyTransform = CGRect(
                x: bounds.minX,
                y: bounds.minY + headerHeight + middleHeight,
                width: bounds.width,
                height: floatingHeight
            )
            
            let contentHeight = {
                var height = self.calculateHeight(for: self.contentView)
                if self.contentScrollView != nil {
                    height = min(height, bounds.height)
                }
                return height
            }()
            self.contentView?.frame = CGRect(
                x: bounds.minX,
                y: bounds.minY + headerHeight + middleHeight + floatingHeight,
                width: bounds.width,
                height: contentHeight
            )
            
            self.containerView.js_frameApplyTransform = CGRect(
                x: bounds.minX,
                y: bounds.minY,
                width: bounds.width,
                height: bounds.minY + headerHeight + middleHeight + floatingHeight + contentHeight
            )
            
            self.updateScrollSettings()
            
            let isContentSizeChanged = self.updateContentSize()
            if isContentSizeChanged {
                self.handleDidScoll()
            }
        }
        
        self.updateFloatingState()
    }
    
    open override func touchesShouldCancel(in view: UIView) -> Bool {
        // 默认情况下只有当view是非UIControl的时候才会返回YES，这里统一对UIControl也返回YES
        guard view is UIControl else {
            return super.touchesShouldCancel(in: view)
        }
        return true
    }
    
    open override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
        guard !super.accessibilityScroll(direction) else {
            return true
        }
        
        let contentOffset = { () -> CGPoint? in
            let offset = self.bounds.height / 1.5
            switch direction {
            case .up:
                return CGPoint(x: self.contentOffset.x, y: self.contentOffset.y - offset)
            case .down:
                return CGPoint(x: self.contentOffset.x, y: self.contentOffset.y + offset)
            default:
                return nil
            }
        }()
        guard let contentOffset = contentOffset else {
            return false
        }
        self.js_scroll(toOffset: contentOffset, animated: true)
        UIAccessibility.post(notification: .pageScrolled, argument: nil)
        return true
    }
    
}

extension NestedScrollView {
    
    @objc public func updateLayout() {
        self.isNeedsLayout = true
        self.setNeedsLayout()
    }
    
    @objc(scrollToHeaderViewWithOffset:animated:)
    public func scrollToHeaderView(with offset: CGPoint, animated: Bool) {
        var contentOffset = self.headerViewMinimumPosition
        contentOffset.x += offset.x
        contentOffset.y += offset.y
        self.js_scroll(toOffset: contentOffset, animated: animated)
    }
    
    @objc(scrollToMiddleViewWithOffset:animated:)
    public func scrollToMiddleView(with offset: CGPoint, animated: Bool) {
        var contentOffset = self.middleViewMinimumPosition
        contentOffset.x += offset.x
        contentOffset.y += offset.y
        self.js_scroll(toOffset: contentOffset, animated: animated)
    }
    
    @objc(scrollToContentViewWithOffset:animated:)
    public func scrollToContentView(with offset: CGPoint, animated: Bool) {
        var contentOffset = self.contentViewMinimumPosition
        contentOffset.x += offset.x
        contentOffset.y += offset.y
        self.js_scroll(toOffset: contentOffset, animated: animated)
    }
    
    @objc(scrollToView:withOffset:animated:)
    public func scrollTo(_ view: UIView, with offset: CGPoint, animated: Bool) {
        if view == self.headerView || view == self.headerScrollView {
            self.scrollToHeaderView(with: offset, animated: animated)
        } else if view == self.middleView {
            self.scrollToMiddleView(with: offset, animated: animated)
        } else if view == self.contentView || view == self.contentScrollView {
            self.scrollToContentView(with: offset, animated: animated)
        } else {
            assertionFailure("不支持此View")
        }
    }
    
    @objc public var headerViewMinimumPosition: CGPoint {
        return self.js_minimumContentOffset
    }
    
    @objc public var middleViewMinimumPosition: CGPoint {
        return CGPoint(
            x: self.js_minimumContentOffset.x,
            y: self.js_minimumContentOffset.y + self.headerViewContentHeight
        )
    }
    
    @objc public var contentViewMinimumPosition: CGPoint {
        return CGPoint(
            x: self.js_minimumContentOffset.x,
            y: self.js_minimumContentOffset.y + self.headerViewContentHeight + (self.middleView?.bounds.height ?? 0) + self.adjustedContentInset.top - self.floatingOffset
        )
    }
    
}

extension NestedScrollView {
    
    private var headerScrollView: UIScrollView? {
        guard let scrollView = self.headerView?.preferredScrollView?(in: self) else {
            return nil
        }
        return scrollView
    }
    
    private var headerViewContentHeight: CGFloat {
        let headerHeight = self.headerView?.bounds.height ?? 0
        var headerContentHeight = 0.0
        if let headerScrollView = self.headerScrollView {
            headerContentHeight = headerScrollView.contentSize.height
            headerContentHeight += headerScrollView.adjustedContentInset.jsc.vertical
            /// 内容高度小于视图本身的高度时, 需要设置为视图本身的高度
            headerContentHeight = max(headerContentHeight, headerHeight)
        } else {
            headerContentHeight = headerHeight
        }
        return headerContentHeight
    }
    
    private var contentScrollView: UIScrollView? {
        guard let scrollView = self.contentView?.preferredScrollView?(in: self) else {
            return nil
        }
        return scrollView
    }
    
    private var contentViewContentHeight: CGFloat {
        let contentViewHeight = self.contentView?.bounds.height ?? 0
        var contentViewContentHeight = 0.0
        if let contentScrollView = self.contentScrollView {
            contentViewContentHeight = contentScrollView.contentSize.height
            contentViewContentHeight += contentScrollView.adjustedContentInset.jsc.vertical
            /// 内容高度小于视图本身的高度时, 需要设置为视图本身的高度
            contentViewContentHeight = max(contentViewContentHeight, contentViewHeight)
        } else {
            contentViewContentHeight = contentViewHeight
        }
        return contentViewContentHeight
    }
    
    private func calculateHeight(for subview: (UIView & NestedScrollViewSupplementarySubview)?) -> CGFloat {
        guard let subview = subview, subview.superview == self.containerView else {
            return 0
        }
        
        var result = NestedScrollView.automaticDimension
        if let height = subview.preferredHeight?(in: self) {
            result = height
        }
        if result < 0 {
            if let scrollSubview = subview as? NestedScrollViewScrollSubview, let scrollView = scrollSubview.preferredScrollView?(in: self) {
                result = scrollView.contentSize.height + scrollView.adjustedContentInset.jsc.vertical
            } else {
                result = subview.sizeThatFits(self.bounds.size).height
                result = result > 0 ? result : subview.bounds.height
            }
        }
        return max(result, 0)
    }
    
    private func addSubview(_ newView: UIView?, oldView: UIView?) {
        if oldView != newView {
            oldView?.removeFromSuperview()
            
            if let newView = newView {
                newView.removeFromSuperview()
                self.containerView.addSubview(newView)
            }
            
            self.updateLayout()
        }
        
        let oldScrollView = (oldView as? NestedScrollViewScrollSubview)?.preferredScrollView?(in: self)
        let newScrollView = (newView as? NestedScrollViewScrollSubview)?.preferredScrollView?(in: self)
        if let oldScrollView = oldScrollView, oldScrollView != newScrollView {
            NestedScrollMediator.resetScrollView(oldScrollView)
        }
        if let newScrollView = newScrollView {
            NestedScrollMediator.handleScrollView(newScrollView, in: self, didScrollHandler: self.scrollSubviewDidScrollHandler)
        }
        
        /// floatingView
        if let floatingView = self.floatingView, floatingView != self.containerView.subviews.last {
            self.containerView.bringSubviewToFront(floatingView)
        }
    }
    
    private func updateScrollSettings() {
        if !self.showsVerticalScrollIndicator {
            self.showsVerticalScrollIndicator = true
        }
        if let headerScrollView = self.headerScrollView {
            if headerScrollView.showsVerticalScrollIndicator {
                headerScrollView.showsVerticalScrollIndicator = false
            }
            if headerScrollView.scrollsToTop {
                headerScrollView.scrollsToTop = false
            }
            if headerScrollView.contentInsetAdjustmentBehavior != .never {
                headerScrollView.contentInsetAdjustmentBehavior = .never
            }
        }
        if let contentScrollView = self.contentScrollView {
            if contentScrollView.showsVerticalScrollIndicator {
                contentScrollView.showsVerticalScrollIndicator = false
            }
            if contentScrollView.scrollsToTop {
                contentScrollView.scrollsToTop = false
            }
            if contentScrollView.contentInsetAdjustmentBehavior != .never {
                contentScrollView.contentInsetAdjustmentBehavior = .never
            }
        }
    }
    
    private func updateContentSize() -> Bool {
        let headerContentHeight = self.headerViewContentHeight
        let contentViewContentHeight = self.contentViewContentHeight
        let middleHeight = self.middleView?.bounds.height ?? 0
        let floatingHeight = self.floatingView?.bounds.height ?? 0
        
        let contentSize = CGSize(width: self.bounds.width, height: headerContentHeight + middleHeight + floatingHeight + contentViewContentHeight)
        guard self.contentSize.jsc.estimated() != contentSize.jsc.estimated() else {
            return false
        }
        self.contentSize = contentSize
        return true
    }
    
    private func handleDidScoll() {
        let containerView = self.containerView
        
        let headerHeight = self.headerView?.bounds.height ?? 0
        let headerViewContentHeight = self.headerScrollView != nil ? self.headerViewContentHeight : headerHeight
        let headerLessThanScreen = headerViewContentHeight < self.bounds.height
        
        let contentHeight = self.contentView?.bounds.height ?? 0
        let contentLessThanScreen = contentHeight < self.bounds.height
        
        let middleHeight = self.middleView?.bounds.height ?? 0
        let floatingHeight = self.floatingView?.bounds.height ?? 0
        
        let prefixContentHeight = headerViewContentHeight + middleHeight + floatingHeight
        let maximumOffsetY = headerViewContentHeight - headerHeight
        let contentOffsetY = self.contentOffset.y
        if contentOffsetY <= maximumOffsetY {
            /// container
            if contentOffsetY <= self.js_minimumContentOffset.y {
                if headerLessThanScreen {
                    self.updateView(containerView, translationY: 0)
                } else {
                    self.updateView(containerView, translationY: contentOffsetY - self.js_minimumContentOffset.y)
                }
            } else if contentOffsetY > self.js_minimumContentOffset.y && contentOffsetY <= 0 {
                self.updateView(containerView, translationY: 0)
            } else {
                self.updateView(containerView, translationY: contentOffsetY)
            }
            
            /// header
            if let headerScrollView = self.headerScrollView {
                var headerMinimumContentOffset = headerScrollView.js_minimumContentOffset
                if contentOffsetY <= self.js_minimumContentOffset.y {
                    if headerLessThanScreen {
                        self.updateScrollView(headerScrollView, contentOffset: headerMinimumContentOffset)
                    } else {
                        headerMinimumContentOffset.y += contentOffsetY
                        headerMinimumContentOffset.y -= self.js_minimumContentOffset.y
                        self.updateScrollView(headerScrollView, contentOffset: headerMinimumContentOffset)
                    }
                } else if contentOffsetY > self.js_minimumContentOffset.y && contentOffsetY <= 0 {
                    self.updateScrollView(headerScrollView, contentOffset: headerMinimumContentOffset)
                } else {
                    headerMinimumContentOffset.y += contentOffsetY
                    self.updateScrollView(headerScrollView, contentOffset: headerMinimumContentOffset)
                }
            }
            
            /// content
            if let contentScrollView = self.contentScrollView {
                self.updateScrollView(contentScrollView, contentOffset: contentScrollView.js_minimumContentOffset)
            }
        } else {
            if contentOffsetY <= prefixContentHeight || contentLessThanScreen {
                /// container
                self.updateView(containerView, translationY: maximumOffsetY)
                
                /// header
                if let headerScrollView = self.headerScrollView {
                    self.updateScrollView(headerScrollView, contentOffset: headerScrollView.js_maximumContentOffset)
                }
                
                /// content
                if let contentScrollView = self.contentScrollView {
                    self.updateScrollView(contentScrollView, contentOffset: contentScrollView.js_minimumContentOffset)
                }
            } else if contentOffsetY < self.js_maximumContentOffset.y - self.adjustedContentInset.bottom {
                /// container
                self.updateView(containerView, translationY: maximumOffsetY + (contentOffsetY - prefixContentHeight))
                
                /// header
                if let headerScrollView = self.headerScrollView {
                    self.updateScrollView(headerScrollView, contentOffset: headerScrollView.js_maximumContentOffset)
                }
                
                /// content
                if let contentScrollView = self.contentScrollView {
                    var contentScrollOffset = contentScrollView.js_minimumContentOffset
                    contentScrollOffset.y += contentOffsetY
                    contentScrollOffset.y -= prefixContentHeight
                    self.updateScrollView(contentScrollView, contentOffset: contentScrollOffset)
                }
            } else if contentOffsetY < self.js_maximumContentOffset.y {
                /// container
                self.updateView(containerView, translationY: maximumOffsetY + self.js_maximumContentOffset.y - prefixContentHeight - self.adjustedContentInset.bottom)
                
                /// header
                if let headerScrollView = self.headerScrollView {
                    self.updateScrollView(headerScrollView, contentOffset: headerScrollView.js_maximumContentOffset)
                }
                
                /// content
                if let contentScrollView = self.contentScrollView {
                    self.updateScrollView(contentScrollView, contentOffset: contentScrollView.js_maximumContentOffset)
                }
            } else {
                /// container
                if self.headerScrollView != nil || self.contentScrollView != nil {
                    self.updateView(containerView, translationY: maximumOffsetY + contentOffsetY - prefixContentHeight - self.adjustedContentInset.bottom)
                } else {
                    self.updateView(containerView, translationY: 0)
                }
                
                /// header
                if let headerScrollView = self.headerScrollView {
                    self.updateScrollView(headerScrollView, contentOffset: headerScrollView.js_maximumContentOffset)
                }
                
                /// content
                if let contentScrollView = self.contentScrollView {
                    var contentScrollOffset = contentScrollView.js_minimumContentOffset
                    contentScrollOffset.y += contentOffsetY
                    contentScrollOffset.y -= prefixContentHeight
                    contentScrollOffset.y -= self.adjustedContentInset.bottom
                    self.updateScrollView(contentScrollView, contentOffset: contentScrollOffset)
                }
            }
        }
        
        /// floating
        if let floatingView = self.floatingView {
            let finallyFloatingHeight = floatingHeight + self.floatingOffset
            let maximumFloatingOffsetY = prefixContentHeight - finallyFloatingHeight
            if contentOffsetY < maximumFloatingOffsetY {
                self.updateView(floatingView, translationY: 0)
            } else if contentOffsetY >= maximumFloatingOffsetY && (contentOffsetY <= prefixContentHeight || contentLessThanScreen) {
                self.updateView(floatingView, translationY: finallyFloatingHeight + (contentOffsetY - prefixContentHeight))
            } else if contentOffsetY < self.js_maximumContentOffset.y - self.adjustedContentInset.bottom {
                self.updateView(floatingView, translationY: finallyFloatingHeight)
            } else if contentOffsetY < self.js_maximumContentOffset.y {
                self.updateView(floatingView, translationY: finallyFloatingHeight + contentOffsetY - self.js_maximumContentOffset.y + self.adjustedContentInset.bottom)
            } else {
                self.updateView(floatingView, translationY: finallyFloatingHeight + self.adjustedContentInset.bottom)
            }
        }
        
        if let scrollView = self.headerScrollView {
            self.assertScrollView(scrollView)
        }
        if let scrollView = self.contentScrollView {
            self.assertScrollView(scrollView)
        }
    }
    
    private func updateFloatingState() {
        let isFloating = {
            let boundsSize = self.bounds.size
            let contentSize = self.contentSize
            guard boundsSize.jsc.isValidated && contentSize.jsc.isValidated else {
                return false
            }
            let headerHeight = self.headerView?.bounds.height ?? 0
            let middleHeight = self.middleView?.bounds.height ?? 0
            if headerHeight == 0 && middleHeight == 0 {
                return true
            } else {
                return self.contentOffset.y >= self.contentViewMinimumPosition.y
            }
        }()
        guard self.isFloating != isFloating else {
            return
        }
        self.isFloating = isFloating
    }
    
    private func updateScrollView(_ scrollView: UIScrollView, contentOffset: CGPoint) {
        guard scrollView.contentOffset.jsc.estimated() != contentOffset.jsc.estimated() else {
            return
        }
        NestedScrollMediator.setContentOffset(contentOffset, for: scrollView)
    }
    
    private func updateView(_ view: UIView, translationY: CGFloat) {
        guard view.transform.ty.jsc.estimated() != translationY.jsc.estimated() else {
            return
        }
        view.transform = CGAffineTransform(translationX: view.transform.tx, y: translationY)
    }
    
    private func assertScrollView(_ scrollView: UIScrollView) {
#if DEBUG
        let message = "estimated特性会导致contenSize计算不准确, 产生跳动的问题"
        if let tableView = scrollView as? UITableView {
            assert(tableView.estimatedRowHeight == 0 && tableView.estimatedSectionHeaderHeight == 0 && tableView.estimatedSectionFooterHeight == 0, message)
        }
        if let collectionView = scrollView as? UICollectionView, let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            assert(layout.estimatedItemSize == CGSize.zero, message)
        }
        
        if scrollView.bounds.size.jsc.isValidated, let superview = scrollView.superview, superview.bounds.size.jsc.isValidated && self.isDescendant(of: superview) {
            assert(scrollView.bounds.size == superview.bounds.size, "scrollView布局没有充满父视图，会造成滑动异常，请添加contentInst以设置其余的视图")
        }
#endif
    }
    
}

extension NestedScrollView: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer, let otherGestureRecognizer = otherGestureRecognizer as? UIPanGestureRecognizer else {
            return false
        }
        /// 两者的手势均为「垂直|」滑动
        let isVerticalScroll = {
            let velocity = gestureRecognizer.velocity(in: gestureRecognizer.view)
            let otherVelocity = otherGestureRecognizer.velocity(in: otherGestureRecognizer.view)
            return abs(velocity.x) <= abs(velocity.y) && abs(otherVelocity.x) <= abs(otherVelocity.y)
        }()
        guard isVerticalScroll else {
            return false
        }
        if let scrollView = self.headerScrollView, scrollView == otherGestureRecognizer.view {
            return true
        } else if let scrollView = self.contentScrollView, scrollView == otherGestureRecognizer.view {
            return true
        } else {
            return false
        }
    }
    
}
