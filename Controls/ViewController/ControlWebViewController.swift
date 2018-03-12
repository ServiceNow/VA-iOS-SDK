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
        
        if #available(iOS 11.0, *) {
            webView.scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([webView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
                                     webView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
                                     webView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
                                     webView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10)])
        
        self.webView = webView
    }
    
    // MARK: - Request Loading
    
    private func loadInitialRequest() {
        switch self.initialRequest {
        case let .html(html):
            webView.loadHTMLString(html, baseURL: nil)
        case let .url(url):
            let request = resourceProvider.authorizedRequest(with: url)
            webView.load(request)
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {

    }
}
