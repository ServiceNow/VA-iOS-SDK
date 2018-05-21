//
//  Chatterbox+TransportNotifications.swift
//  SnowChat
//
//  Created by Marc Attinasi on 2/27/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

extension Chatterbox: TransportStatusListener {

    private static var alreadySynchronizing = false
    
    // MARK: - handle transport notifications
    
    func apiManagerTransportDidBecomeUnavailable(_ apiManager: APIManager) {
        logger.logInfo("Transport is unavailable")
        
        notifyEventListeners { listener in
            listener.chatterbox(self, didReceiveTransportStatus: .unreachable, forChat: chatId)
        }
    }

    func apiManagerTransportIsReconnecting(_ apiManager: APIManager) {
        logger.logDebug("Transport is reconnecting...")

        notifyEventListeners { listener in
            listener.chatterbox(self, didReceiveTransportStatus: .reconnecting, forChat: chatId)
        }
    }

    func apiManagerTransportDidBecomeAvailable(_ apiManager: APIManager) {
        logger.logDebug("Transport is available")

        notifyEventListeners { listener in
            listener.chatterbox(self, didReceiveTransportStatus: .reachable, forChat: chatId)
        }
        
        guard !Chatterbox.alreadySynchronizing, conversationContext.conversationId != nil else { return }
        
        logger.logInfo("Synchronizing conversations due to transport becoming available")
        Chatterbox.alreadySynchronizing = true
        refreshChatSession {
            Chatterbox.alreadySynchronizing = false
        }
    }
    
    func apiManagerAuthenticationDidBecomeInvalid(_ apiManager: APIManager) {
        logger.logInfo("Authorization failed!")
        
        notifyAuthListeners { listener in
            listener.chatterboxAuthenticationDidBecomeInvalid(self)
        }
    }
}
