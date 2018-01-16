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
    static let currentVersion = 1
    
    var version: Int
    var consumerAccountId: String
    var conversationIds: [String]
    
    init(consumerAccountId: String, conversationIds: [String]?) {
        version = StorableContainer.currentVersion
        
        self.consumerAccountId = consumerAccountId
        
        if let conversationIds = conversationIds {
            self.conversationIds = conversationIds
        } else {
            self.conversationIds = [String]()
        }
    }
}

extension ChatDataStore {
    
    // MARK: - Persistence methods
    
    func store() throws {
        guard let consumerAccountId = consumerAccountId else {
            try clearPersistence()
            throw ChatterboxError.invalidParameter(details: "consumerAccountId is not set! cannot store")
        }
        
        guard let archiveURL = archiveURL else {
            throw ChatterboxError.invalidParameter(details: "No archive URL in ChatDataStore.store")
        }
        
        let storable = StorableContainer(consumerAccountId: consumerAccountId, conversationIds: conversationIds())
        let data = try CBData.jsonEncoder.encode(storable)
        try data.write(to: archiveURL)
    }
    
    func load() throws -> [String]? {
        guard let archiveURL = archiveURL else {
            throw ChatterboxError.invalidParameter(details: "No archive URL in ChatDataStore.store")
        }

        guard FileManager().fileExists(atPath: archiveURL.path) else {
            return nil
        }
        
        let data = try Data(contentsOf: archiveURL, options: [])
        
        let storable = try CBData.jsonDecoder.decode(StorableContainer.self, from: data)
        if storable.version != StorableContainer.currentVersion {
            try clearPersistence()
            return nil
        }
        
        consumerAccountId = storable.consumerAccountId
        return storable.conversationIds
    }
    
    private func clearPersistence() throws {
        guard let archiveURL = archiveURL else {
            throw ChatterboxError.invalidParameter(details: "No archive URL in ChatDataStore.store")
        }

        try FileManager().removeItem(atPath: archiveURL.path)
    }
    
}
