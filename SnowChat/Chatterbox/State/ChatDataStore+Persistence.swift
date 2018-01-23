//
//  ChatDataStore+Persistence.swift
//  SnowChat
//
//  Created by Marc Attinasi on 1/10/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

private let documentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first
private let archiveURL = documentsDirectory?.appendingPathComponent("chatstore")

internal class StorableContainer: Codable {
    static let currentVersion = 2
    
    var version: Int
    var conversations: [Conversation]
    
    init(conversations: [Conversation]) {
        version = StorableContainer.currentVersion
        
        self.conversations = conversations
    }
}

extension ChatDataStore {
    
    // MARK: - Persistence methods
    
    func save() throws {
        guard conversationIds().count > 0 else {
            try clearPersistence()
            return
        }
        
        guard let archiveURL = archiveURL else {
            throw ChatterboxError.invalidParameter(details: "No archive URL in ChatDataStore.store")
        }
        
        let storable = StorableContainer(conversations: conversations)
        let data = try CBData.jsonEncoder.encode(storable)
        try data.write(to: archiveURL)
    }
    
    func load() throws -> [Conversation] {
        guard let archiveURL = archiveURL else {
            throw ChatterboxError.invalidParameter(details: "No archive URL in ChatDataStore.store")
        }

        guard FileManager().fileExists(atPath: archiveURL.path) else {
            return []
        }
        
        let data = try Data(contentsOf: archiveURL, options: [])
        
        let storable = try CBData.jsonDecoder.decode(StorableContainer.self, from: data)
        
        if storable.version != StorableContainer.currentVersion {
            // TODO: try to do a version-change-fixup?
            
            try clearPersistence()
            return []
        }
        
        return storable.conversations
    }
    
    private func clearPersistence() throws {
        guard let archiveURL = archiveURL else {
            throw ChatterboxError.invalidParameter(details: "No archive URL in ChatDataStore.store")
        }

        try FileManager().removeItem(atPath: archiveURL.path)
    }
}
