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
        if let control = controlsToReuse[model.type]?.last {
            // update uiControl for a given model. Internally it will update UIViewController
            control.model = model
            controlsToReuse[model.type]?.removeLast()
            return control
        }
        
        let uiControl = ControlsUtil.controlForViewModel(model)
        uiControlByType[model.id] = uiControl
        return uiControl
    }
    
    func prepareControlForReuse(withModel model: ControlViewModel) {
        if let control = uiControlByType[model.id] {
            if var controlsList = controlsToReuse[model.type] {
                controlsList.append(control)
            } else {
                controlsToReuse[model.type] = [control]
            }
            
            uiControlByType.removeValue(forKey: model.id)
        }
    }
}
