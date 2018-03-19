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
    
    enum Request {
        case url(URL)
        case html(String)
    }
    
    var hasNavigated: Bool {
        // Did user navigated within the web view?
        return webView.backForwardList.backItem != nil
    }
    
    private(set) var webView: WKWebView!
    private let initialRequest: Request
    private let resourceProvider: ControlWebResourceProvider
    
    // MARK: - Initialization
    
    convenience init(url: URL, resourceProvider: ControlWebResourceProvider) {
        self.init(initialRequest: .url(url), resourceProvider: resourceProvider)
    }
    
    convenience init(htmlString: String, resourceProvider: ControlWebResourceProvider) {
        self.init(initialRequest: .html(htmlString), resourceProvider: resourceProvider)
    }
    
    private init(initialRequest: Request, resourceProvider: ControlWebResourceProvider) {
        self.initialRequest = initialRequest
        self.resourceProvider = resourceProvider
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupWebView()
        loadInitialRequest()
    }
    
    // MARK: - Setup
    
    private func setupWebView() {
        let webView = WKWebView(frame: CGRect.zero, configuration: resourceProvider.webViewConfiguration)
        webView.navigationDelegate = self
        
        // Scroll view inside scroll view is...pretty ugly. Especially when adjustment is on!
        if #available(iOS 11.0, *) {
            webView.scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([webView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5),
                                     webView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5),
                                     webView.topAnchor.constraint(equalTo: view.topAnchor, constant: 5),
                                     webView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -5)])
        
        self.webView = webView
    }
    
    func load(_ url: URL) {
        load(.url(url))
    }
    
    func load(_ htmlString: String) {
        load(.html(htmlString))
    }
    
    private func load(_ request: Request) {
        switch request {
        case let .html(html):
            let viewportDirective = "<meta name=\"viewport\" content=\"initial-scale=1.0, shrink-to-fit=no\" />"
            let scaledHTML = viewportDirective + html
            webView.loadHTMLString(scaledHTML, baseURL: nil)
        case let .url(url):
            let request = resourceProvider.authorizedRequest(with: url)
            webView.load(request)
        }
    }
    
    // MARK: - Request Loading
    
    private func loadInitialRequest() {
        load(initialRequest)
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
}
