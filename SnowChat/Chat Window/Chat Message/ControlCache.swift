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
    
    private var uiControlByModelId = [String: ControlProtocol]()
    private var controlsToReuse = [ControlType: [ControlProtocol]]()
    
    func control(forModel model: ControlViewModel, forResourceProvider provider: ControlResourceProvider? = nil) -> ControlProtocol {     
        if let storedControl = uiControlByModelId[model.id] {
            return storedControl
        }
        
        let uiControl: ControlProtocol
        if let control = controlsToReuse[model.type]?.popLast() {
            // update uiControl for a given model. Internally it will update UIViewController
            control.model = model
            uiControl = control
        } else {
            uiControl = ControlsUtil.controlForViewModel(model, resourceProvider: provider)
        }
        
        uiControlByModelId[model.id] = uiControl
        return uiControl
    }
    
    func cacheControl(forModel model: ControlViewModel) {
        guard let control = uiControlByModelId[model.id], control.model.type == model.type else {
            Logger.default.logDebug("Can't find control with model id: \(model.id)")
            return
        }

        control.prepareForReuse()
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
