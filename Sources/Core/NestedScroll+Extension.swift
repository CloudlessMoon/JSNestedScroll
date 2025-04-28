//
//  NestedScroll+Extension.swift
//  JSNestedScroll
//
//  Created by jiasong on 2024/12/6.
//

import UIKit
import WebKit

extension UIScrollView: NestedScrollViewScrollSubview {
    
    @objc public func preferredScrollView(in nestedScrollView: NestedScrollView) -> UIScrollView? {
        return self
    }
    
}

extension WKWebView: NestedScrollViewScrollSubview {
    
    @objc public func preferredScrollView(in nestedScrollView: NestedScrollView) -> UIScrollView? {
        return self.scrollView
    }
    
}
