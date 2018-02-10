//
//  ControlWebViewController.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/7/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import UIKit
import WebKit

class ControlWebViewController: UIViewController, WKNavigationDelegate {
    
    private var request: URLRequest?
    private var htmlString: String?
    private(set) var webView: WKWebView?
    private let fullSizeContainer = FullSizeScrollViewContainerView()
    
    init(request: URLRequest) {
        self.request = request
        super.init(nibName: nil, bundle: nil)
    }
    
    init(htmlString: String) {
        self.htmlString = htmlString
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = fullSizeContainer
    }
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
    }
    
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.suppressesIncrementalRendering = true
        
        // TODO: Make it shared like in NOW app?
        configuration.processPool = WKProcessPool()
        configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        
        let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        
        fullSizeContainer.maxHeight = 400
        fullSizeContainer.scrollView = webView.scrollView
        webView.translatesAutoresizingMaskIntoConstraints = false
        fullSizeContainer.addSubview(webView)
        NSLayoutConstraint.activate([webView.leadingAnchor.constraint(equalTo: fullSizeContainer.leadingAnchor),
                                     webView.trailingAnchor.constraint(equalTo: fullSizeContainer.trailingAnchor),
                                     webView.topAnchor.constraint(equalTo: fullSizeContainer.topAnchor),
                                     webView.bottomAnchor.constraint(equalTo: fullSizeContainer.bottomAnchor)])
        
        if let request = self.request {
            webView.load(request)
        }
        
        if let htmlString = htmlString {
            webView.loadHTMLString(htmlString, baseURL: nil)
        }
        
        self.webView = webView
    }
}
