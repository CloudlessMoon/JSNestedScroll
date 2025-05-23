//
//  NestedScrollViewController.swift
//  JSNestedScrollExample
//
//  Created by jiasong on 2022/11/7.
//

import UIKit
import JSNestedScroll
import Then
import QMUIKit
import MJRefresh

class NestedScrollViewController: QMUICommonViewController {
    
    lazy var nestedScrollView: NestedScrollView = {
        return NestedScrollView().then {
            $0.backgroundColor = UIColor.clear
        }
    }()
    
    lazy var headerView: NestedScrollListView = {
        return NestedScrollListView().then {
            $0.textPrefix = "Header"
        }
    }()
    
    lazy var middleView: NestedScrollSupplementaryView = {
        return NestedScrollSupplementaryView().then {
            $0.backgroundColor = UIColor.yellow.withAlphaComponent(0.2)
        }
    }()
    
    lazy var contentView: NestedScrollListView = {
        return NestedScrollListView().then {
            $0.textPrefix = "Content"
        }
    }()
    
    lazy var floatingView: NestedScrollFloatingView = {
        return NestedScrollFloatingView().then {
            $0.backgroundColor = UIColor.blue.withAlphaComponent(0.2)
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.view.addSubview(self.nestedScrollView)
        
        self.nestedScrollView.headerView = self.headerView
        self.nestedScrollView.middleView = self.middleView
        self.nestedScrollView.floatingView = self.floatingView
        self.nestedScrollView.contentView = self.contentView
        
        self.nestedScrollView.mj_header = MJRefreshStateHeader { [unowned self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                self.nestedScrollView.mj_header?.endRefreshing()
            })
        }
        
        self.contentView.tableView.mj_footer = MJRefreshAutoNormalFooter { [unowned self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                self.contentView.numberOfRows += 10
                self.contentView.tableView.mj_footer?.endRefreshing()
            })
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.nestedScrollView.floatingOffset = self.view.safeAreaInsets.top
        self.nestedScrollView.contentInset = UIEdgeInsets(top: self.view.safeAreaInsets.top, left: 0, bottom: self.view.safeAreaInsets.bottom, right: 0)
        
        self.nestedScrollView.frame = self.view.bounds
    }
    
    override func setupNavigationItems() {
        super.setupNavigationItems()
        self.title = "嵌套滚动组件"
        
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem.qmui_item(withTitle: "滚动", target: self, action: #selector(self.onPressScroll)),
                                                   UIBarButtonItem.qmui_item(withTitle: "刷新", target: self, action: #selector(self.onPressRefresh))]
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }
    
    override func preferredNavigationBarHidden() -> Bool {
        return false
    }
    
    override func shouldCustomizeNavigationBarTransitionIfHideable() -> Bool {
        return true
    }
    
    override func qmui_navigationBarBackgroundImage() -> UIImage? {
        return UIImage.qmui_image(with: UIColor.white.withAlphaComponent(1.0))
    }
    
}

extension NestedScrollViewController {
    
    @objc private func onPressScroll() {
        self.contentView.tableView.scrollToRow(at: IndexPath(item: 3, section: 0), at: .top, animated: true)
    }
    
    @objc private func onPressRefresh() {
        self.contentView.numberOfRows = 50
    }
    
}
