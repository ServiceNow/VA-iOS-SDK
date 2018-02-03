//
//  ControlPresentable.swift
//  SnowChat
//
//  Created by Michael Borowiec on 1/31/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

protocol ControlPresentable {
    func addUIControl(_ control: ControlProtocol, at location: BubbleLocation)
}
