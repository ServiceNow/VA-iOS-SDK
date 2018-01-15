//
//  ControlCache.swift
//  SnowChat
//
//  Created by Michael Borowiec on 1/14/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class ControlCache {
    
    typealias ControlListByType = [ControlType : [ControlProtocol]]
    typealias ControlListById = [String : ControlProtocol]
    
    private var uiControlByType = ControlListById()
    private var controlsToReuse = ControlListByType()
    
    func control(forModel model: ControlViewModel) -> ControlProtocol {
        let uiControl: ControlProtocol
        if let control = controlsToReuse[model.type]?.last {
            // update uiControl for a given model. Internally it will update UIViewController
            control.model = model
            controlsToReuse[model.type]?.removeLast()
            uiControl = control
        } else {
            uiControl = ControlsUtil.controlForViewModel(model)
        }
        
        uiControlByType[model.id] = uiControl
        return uiControl
    }
    
    func removeControl(withModel model: ControlViewModel) {
        guard let control = uiControlByType[model.id] else {
            fatalError("Can't find control with model id: \(model.id)")
        }

        if var controlsList = controlsToReuse[model.type] {
            controlsList.append(control)
            controlsToReuse[model.type] = controlsList
        } else {
            controlsToReuse[model.type] = [control]
        }
        
        uiControlByType.removeValue(forKey: model.id)
    }
}
