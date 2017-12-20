//
//  AutoCompleteHandler.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/18/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//
//  AutoCompleteHandler is used to take over the autocomplete tableview facility of the
//  Slack View Controller. We use it differently in different phases of the chat:
//   - topic selection, active conversation, system topic interaction
//
//  This protocol is used to allow different implementations to be plugged-in to the ConversationViewController
//  to allow varying behavior in different situations

import Foundation

protocol AutoCompleteHandler {
    
    func numberOfSections() -> Int
    func numberOfRowsInSection(_ section: Int) -> Int
    
    func heightForAutoCompletionView() -> CGFloat
    
    func cellForRowAt(_ indexPath: IndexPath) -> UITableViewCell
    func viewForHeaderInSection(_ section: Int) -> UIView?
    
    func didChangeAutoCompletionText(withPrefix prefix: String, andWord word: String)
    func didCommitEditing(_ value: String)
    
    func didSelectRowAt(_ indexPath: IndexPath)
}
