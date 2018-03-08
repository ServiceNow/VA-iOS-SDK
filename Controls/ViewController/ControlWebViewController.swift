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
    
    private let initialRequest: Request
    private let resourceProvider: ControlWebResourceProvider
    
    private var webView: WKWebView!
    let fullSizeContainer = FullSizeScrollViewContainerView()
    
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
    
    override func loadView() {
        self.view = fullSizeContainer
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupWebView()
        loadInitialRequest()
    }
    
    // MARK: - Setup
    
    private func setupWebView() {
        let webView = WKWebView(frame: CGRect.zero, configuration: resourceProvider.webViewConfiguration)
        
        fullSizeContainer.maxHeight = 400
        fullSizeContainer.scrollView = webView.scrollView
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        fullSizeContainer.addSubview(webView)
        NSLayoutConstraint.activate([webView.leadingAnchor.constraint(equalTo: fullSizeContainer.leadingAnchor),
                                     webView.trailingAnchor.constraint(equalTo: fullSizeContainer.trailingAnchor),
                                     webView.topAnchor.constraint(equalTo: fullSizeContainer.topAnchor),
                                     webView.bottomAnchor.constraint(equalTo: fullSizeContainer.bottomAnchor)])

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
    
}
