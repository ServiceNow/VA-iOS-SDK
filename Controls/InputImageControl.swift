//
//  InputImageControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/16/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import MobileCoreServices
import Photos

class InputImageControl: NSObject, PickerControlProtocol, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var visibleItemCount: Int = 2
    
    var model: ControlViewModel {
        didSet {
            updateViewController(withModel: model)
        }
    }
    
    var style: PickerControlStyle
    
    public lazy var viewController: UIViewController = {
        let vc = self.viewController(forStyle: style, model: model)
        return vc
    }()
    
    weak var delegate: ControlDelegate?
    
    required init(model: ControlViewModel) {
        guard let inputImageModel = model as? InputImageViewModel else {
            fatalError("Wrong model class")
        }
        
        self.model = inputImageModel
        self.style = .inline
    }
    
    // MARK: - PickerViewControllerDelegate
    
    func pickerViewController(_ viewController: PickerViewController, didFinishWithModel model: PickerControlViewModel) {
        guard let item = model.selectedItem else { return }
        
        // Check if Info.plist has a value for NSPhotoLibraryUsageDescription key. Otherwise the app will crash
        guard let _ = Bundle.main.infoDictionary?["NSPhotoLibraryUsageDescription"] else {
            fatalError("Please provide value for the NSPhotoLibraryUsageDescription key in Info.plist")
        }
        
        // TODO: Bubble up an error if user declined access?
        let autorizationStatus = PHPhotoLibrary.authorizationStatus()
        guard autorizationStatus == .authorized else {
            Logger.default.logError("User didn't autorize access to Photo Library!")
            return
        }
        
        let imagePickerControllerSourceType: UIImagePickerControllerSourceType
        switch item.type {
        case .takePhoto:
            imagePickerControllerSourceType = .camera
        case .photoLibrary:
            guard UIImagePickerController.isCameraDeviceAvailable(.rear) else {
                // TODO: FatalError? Alert?
                return
            }
            imagePickerControllerSourceType = .photoLibrary
        default:
            fatalError("Not supported type")
        }
        
        presentImagePickerControllerWithSourceType(imagePickerControllerSourceType)
    }
    
    func pickerViewController(_ viewController: PickerViewController, didSelectItem item: PickerItem, forPickerModel pickerModel: PickerControlViewModel) {
        
    }
    
    // MARK: - UIImagePickerController
    
    private func presentImagePickerControllerWithSourceType(_ type: UIImagePickerControllerSourceType) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.modalPresentationStyle = .fullScreen
        imagePickerController.cameraDevice = .rear
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = [kUTTypeImage as String]
        self.viewController.present(imagePickerController, animated: true, completion: nil)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        viewController.presentingViewController?.dismiss(animated: true, completion: nil)
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        let imageData = UIImageJPEGRepresentation(image, 0.8)
    }
}
