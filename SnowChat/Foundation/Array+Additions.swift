//
//  Array+Additions.swift
//  SnowChat
//
//  Created by Michael Borowiec on 1/23/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

extension Array where Element == String {
    func joinedWithCommaSeparator() -> String {
        return joined(separator: ", ")
    }
}
