//
//  ControlCache.swift
//  SnowChat
//
//  Created by Michael Borowiec on 1/14/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

// This class is responsible for caching control based on its model type.
// There might be multiple controls of the same type, so we will store it in a list for each model type as a key

class ControlCache {
    
    private var uiControlByModelId = [String : ControlProtocol]()
    private var controlsToReuse = [ControlType : [ControlProtocol]]()
    
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
        
        uiControlByModelId[model.id] = uiControl
        return uiControl
    }
    
    func removeControl(forModel model: ControlViewModel) {
        guard let control = uiControlByModelId[model.id] else {
            Logger.default.logDebug("Can't find control with model id: \(model.id)")
            return
        }

        if var controlsList = controlsToReuse[model.type] {
            controlsList.append(control)
            controlsToReuse[model.type] = controlsList
        } else {
            controlsToReuse[model.type] = [control]
        }
        
        uiControlByModelId.removeValue(forKey: model.id)
    }
    
    func removeAll() {
        uiControlByModelId.removeAll()
        controlsToReuse.removeAll()
    }
}
