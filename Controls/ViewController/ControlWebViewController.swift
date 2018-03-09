//
//  ControlWebViewController.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/7/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import UIKit
import WebKit

protocol ControlWebViewControllerDelegate: AnyObject {
    func webViewController(_ webViewController: ControlWebViewController, didFinishLoadingWebViewWithSize size: CGSize)
}

class ControlWebViewController: UIViewController, WKNavigationDelegate {
    
    weak var uiDelegate: ControlWebViewControllerDelegate?
    
    enum Request {
        case url(URL)
        case html(String)
    }
    
    var hasNavigated: Bool {
        return webView.backForwardList.backItem != nil
    }
    
    private let initialRequest: Request
    private let resourceProvider: ControlWebResourceProvider
    
    private(set) var webView: WKWebView!
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
        webView.navigationDelegate = self
        
        if #available(iOS 11.0, *) {
            webView.scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        
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
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView.isLoading == false {
            webView.evaluateJavaScript("document.body.scrollHeight", completionHandler: { [weak self] (result, error) in
                guard let strongSelf = self else { return }
                
                if let height = result as? CGFloat, let adjustedHeight = [height, strongSelf.fullSizeContainer.maxHeight].min() {
                    let size = CGSize(width: webView.frame.width, height: adjustedHeight)
                    strongSelf.uiDelegate?.webViewController(strongSelf, didFinishLoadingWebViewWithSize: size)
                }
            })
        }
    }
}
