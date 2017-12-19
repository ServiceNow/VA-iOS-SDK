//
//  AutoCompleteHandler.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/18/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

protocol AutoCompleteHandler {
    
    func numberOfSections() -> Int
    func numberOfRowsInSection(_ section: Int) -> Int
    
    func heightForAutoCompletionView() -> CGFloat
    func heightForRowAt(_ indexPath: IndexPath) -> CGFloat
    func heightForHeaderInSection(_ section: Int) -> CGFloat
    
    func cellForRowAt(_ indexPath: IndexPath) -> UITableViewCell
    func viewForHeaderInSection(_ section: Int) -> UIView?
    
    func didChangeAutoCompletionText(withPrefix prefix: String, andWord word: String)
    func didCommitEditing(_ value: String)
    
    func didSelectRowAt(_ indexPath: IndexPath)
}
