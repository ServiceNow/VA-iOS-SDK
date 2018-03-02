//
//  UserData.swift
//  SnowChat
//
//  Created by Michael Borowiec on 3/1/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import AVFoundation
import Photos


class UserData {
    
    // MARK: - Authorization
    
    class func authorizeCamera(_ handler: @escaping (AVAuthorizationStatus) -> Swift.Void) {
        guard nil != Bundle.main.infoDictionary?["NSCameraUsageDescription"] else {
            fatalError("Please provide value for the NSCameraUsageDescription key in Info.plist of your application")
        }
        
        guard UIImagePickerController.isCameraDeviceAvailable(.rear) else {
            DispatchQueue.main.async {
                handler(.denied)
            }
            
            return
        }
        
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if authorizationStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                handler(granted ? .authorized : .denied)
            }
        } else {
            DispatchQueue.main.async {
                handler(authorizationStatus)
            }
        }
    }
    
    class func authorizePhoto(_ handler: @escaping (PHAuthorizationStatus) -> Swift.Void) {
        
        // Check if Info.plist has a value for NSPhotoLibraryUsageDescription key. Otherwise the app will crash
        guard nil != Bundle.main.infoDictionary?["NSPhotoLibraryUsageDescription"] else {
            fatalError("Please provide value for the NSPhotoLibraryUsageDescription key in Info.plist of your application")
        }
        
        let authorizationStatus = PHPhotoLibrary.authorizationStatus()
        if authorizationStatus == .notDetermined {
            PHPhotoLibrary.requestAuthorization({ status in
                handler(status)
            })
        } else {
            DispatchQueue.main.async {
                handler(authorizationStatus)
            }
        }
    }
}
