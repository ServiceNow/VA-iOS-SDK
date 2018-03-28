//
//  FileUploadControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/16/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import MobileCoreServices

class FileUploadControl: NSObject, PickerControlProtocol, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var visibleItemCount: Int = 2
    
    var model: ControlViewModel {
        didSet {
            updateViewController(withModel: model)
        }
    }
    
    private var fileUploadModel: FileUploadViewModel {
        return model as! FileUploadViewModel
    }
    
    var style: PickerControlStyle
    
    public lazy var viewController: UIViewController = {
        let vc = self.viewController(forStyle: style, model: model)
        return vc
    }()
    
    weak var delegate: ControlDelegate?
    
    required init(model: ControlViewModel) {
        guard let inputImageModel = model as? FileUploadViewModel else {
            fatalError("Wrong model class")
        }

        self.model = inputImageModel
        self.style = .list
    }
    
    // MARK: - PickerViewControllerDelegate
    
    func pickerViewController(_ viewController: UIViewController, didFinishWithModel model: PickerControlViewModel) {
        
        // TODO: when we support file upload, we will need to add here appropriate cases
        guard let item = model.selectedItem else { return }
        
        switch item.type {
        case .takePhoto:
            UserDataManager.authorizeCamera({ [weak self] status in
                if status == .authorized {
                    self?.presentImagePickerControllerWithSourceType(.camera)
                }
            })
        case .photoLibrary:
            UserDataManager.authorizePhoto({ [weak self] status in
                if status == .authorized {
                    self?.presentImagePickerControllerWithSourceType(.photoLibrary)
                }
            })
        default:
            fatalError("Not supported type")
        }
    }
    
    func pickerViewController(_ viewController: UIViewController, didSelectItem item: PickerItem, forPickerModel pickerModel: PickerControlViewModel) {
        
    }
    
    // MARK: - UIImagePickerController
    
    private func presentImagePickerControllerWithSourceType(_ type: UIImagePickerControllerSourceType) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = type
        if type == .camera {
            imagePickerController.cameraDevice = .rear
        }
        
        imagePickerController.modalPresentationStyle = .overFullScreen
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = [kUTTypeImage as String]
        viewController.present(imagePickerController, animated: true, completion: nil)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        viewController.presentedViewController?.dismiss(animated: true, completion: nil)
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        if #available(iOS 11.0, *) {
            let imageURL = info[UIImagePickerControllerImageURL] as! URL
            fileUploadModel.imageName = imageURL.deletingPathExtension().lastPathComponent
        } else {
            let imageURL = info[UIImagePickerControllerReferenceURL] as! URL
            fileUploadModel.imageName = imageURL.deletingPathExtension().lastPathComponent
        }
        
        let imageData = UIImageJPEGRepresentation(image, 0.2)
        fileUploadModel.selectedImageData = imageData
        
        delegate?.control(self, didFinishWithModel: model)
    }
}