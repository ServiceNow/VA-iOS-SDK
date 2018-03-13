//
//  Chatterbox+SupportQueue.swift
//  SnowChat
//
//  Created by Marc Attinasi on 3/1/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

extension Chatterbox {
    
    func subscribeToSupportQueue(_ message: SubscribeToSupportQueueMessage) {
        guard let channel = message.channel else {
            logger.logError("SubscribeToSupportQueue message with no channel - ignoring!")
            return
        }
        
        // unsubscribe existing subscription if it is set
        supportQueueSubscription?.unsubscribe()
        
        logger.logInfo("Subscribing to SupportQueue channel \(channel)")
        
        supportQueueSubscription = apiManager.subscribe(channel) { [weak self] (result, subscription) in
            guard let strongSelf = self else { return }
            
            switch result {
            case .success:
                guard let message = result.value else { return }
                
                strongSelf.logger.logDebug("Support Queue Update: \(message.jsonDataString)")
                
                if let jsonData = message.jsonDataString.data(using: .utf8) {
                    do {
                        let supportInfo = try ChatUtil.jsonDecoder.decode(SupportQueue.self, from: jsonData)
                        strongSelf.supportQueueInfo = supportInfo
                    } catch let error {
                        strongSelf.logger.logError("Error decoding SupportQueue AMB message: \(error)")
                    }
                }
                
            case .failure:
                guard let error = result.error else { return }
                strongSelf.logger.logError("AMB error in Support Queue subscription: \(error)")
            }
        }
    }
}
