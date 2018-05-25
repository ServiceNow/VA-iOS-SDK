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
    
    func control(forModel model: ControlViewModel, forResourceProvider provider: ControlResourceProvider) -> ControlProtocol {
        let uiControl: ControlProtocol
        if let control = controlsToReuse[model.type]?.popLast() {
            // update uiControl for a given model. Internally it will update UIViewController
            control.model = model
            uiControl = control
        } else {
            uiControl = ControlsUtil.controlForViewModel(model, resourceProvider: provider)
        }
        
        return uiControl
    }
    
    func cacheControl(_ control: ControlProtocol) {
        control.prepareForReuse()
        
        let model = control.model
        if var controlsList = controlsToReuse[model.type] {
            controlsList.append(control)
            controlsToReuse[model.type] = controlsList
        } else {
            controlsToReuse[model.type] = [control]
        }
    }
    
    func removeAll() {
        uiControlByModelId.removeAll()
        controlsToReuse.removeAll()
    }
}
