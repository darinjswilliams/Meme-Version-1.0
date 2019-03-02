//
//  ViewController.swift
//  MemeMe 1.0
//
//  Created by Darin Williams on 1/14/19.
//  Copyright © 2019 dwilliams. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate{

    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var imagePickerView: UIImageView!
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    @IBOutlet weak var albumButton: UIBarButtonItem!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    
    @IBOutlet weak var topTextField: UITextField!
    
    @IBOutlet weak var bottomTextField: UITextField!
    
    
    struct Meme {
        var topText: String
        var bottomText: String
        var originalImage: UIImage?
        var memedImage: UIImage?
    }
    
    let memeTextAttributes:[NSAttributedString.Key: Any] = [
        NSAttributedString.Key(rawValue: NSAttributedString.Key.strokeColor.rawValue): UIColor.black,
        NSAttributedString.Key(rawValue: NSAttributedString.Key.foregroundColor.rawValue): UIColor.white,
        NSAttributedString.Key(rawValue: NSAttributedString.Key.font.rawValue): UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
        NSAttributedString.Key(rawValue: NSAttributedString.Key.strokeWidth.rawValue): -4.0]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set text fields initial values
        commonTextAttributes(textField: topTextField, textSource: "TOP")
        commonTextAttributes(textField: bottomTextField, textSource: "BOTTOM")
        
        shareButton.isEnabled = false

        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //disable button if device does not have a camera
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        
        subscribeToKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    //MARK set text fields initial string value and align center with default attributes
    func commonTextAttributes(textField: UITextField, textSource text: String){
        
       
        textField.defaultTextAttributes = memeTextAttributes
        textField.text = text
        textField.textAlignment = .center
        textField.delegate = self
        
    }
    
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text == "TOP" || textField.text == "BOTTOM" {
            textField.text = ""
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        textField.resignFirstResponder()
        
        return true
    }

    //MARK subscribe to keyboard notifications
    func subscribeToKeyboardNotifications(){
        
        //Show keyboardWillShow Notification
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        //Hide keyboardWillHide notification
           NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
     //MARK unsubscribe from Keyboard Notifications
    func unsubscribeFromKeyboardNotifications(){
        
        //Notification Keyboard will show
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        
        //Notification Keyboard will hide
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    //MARK shift keyboard up after recieving notification by subtracting
    //height of keyboard
    @objc func keyboardWillShow(_ notification:Notification) {
        
        if bottomTextField.isFirstResponder{
           self.view.frame.origin.y = -getKeyboardHeight(notification)
        }
    }
    
    //MARK hide keyboard to shift backdown
    @objc func keyboardWillHide(_ notification:Notification){
        if self.view.frame.origin.y != 0 {
             self.view.frame.origin.y = 0
        }
       
    }
    
    func getKeyboardHeight(_ notification:Notification) -> CGFloat {
        
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.cgRectValue.height
    }
    
    func processImageSource(sourceType: UIImagePickerController.SourceType){
        
        shareButton.isEnabled = true
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = sourceType
        
        present(imagePicker, animated: true, completion: nil)
        
    }
    
    
    @IBAction func cancelImageSelection(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePickerControllerDidCancel(imagePicker)
        commonTextAttributes(textField: topTextField, textSource: "TOP")
        commonTextAttributes(textField: bottomTextField, textSource: "BOTTOM")
        shareButton.isEnabled = false
    }
    
    //MARK Pick an Image from Camera
    @IBAction func pickAnImageFromCamera(_ sender: Any) {
        
        processImageSource(sourceType: .camera)
    }
    
    //MARK Pick an Image from Photo Library
    @IBAction func pickAnImageFromAlbum(_ sender: Any) {
     
        processImageSource(sourceType: .photoLibrary)
    }
    
    //Mark Cancel Image Selection
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    
    //Mark Pick an Image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let image = info[.originalImage] as? UIImage
            else {
                fatalError("Expected a dictionary image but was provided the follow \(info)")
        }
      
          imagePickerView.image = image
        
        dismiss(animated: true, completion: nil)
      }
    
    
    //Mark Share Meme Images
    @IBAction func shareImages(_ sender: Any) {
        //Generate a memed Image
        let sharedMemedImage: UIImage = generateMemedImage()

        //Get Instance of ActivityViewController
        //pass the AcitivityViewController  a memedImage as an activity item
        let activityController = UIActivityViewController(activityItems: [sharedMemedImage], applicationActivities: nil)
        
        
        //pass the activitview controller as a memed image
        activityController.completionWithItemsHandler = { (activity, success, items, error) -> Void in
            
            if(success) {
                self.save()
            }
        }
        
        //Present the ActivityViewController
        self.present(activityController, animated: true, completion: nil)
      
 }
    
    //Mark save meme
    func save(){
        
        // Create a meme
        let sharedMemedImage: UIImage = generateMemedImage()
        _ = Meme(topText: topTextField.text!, bottomText: bottomTextField.text!,
                        originalImage: imagePickerView.image!, memedImage: sharedMemedImage)
        
        //Dimiss the acitivity afer object has been saved
        dismiss(animated: true, completion: nil)
        
    }
    
    //MARK combine image and test to create memedImage
    func generateMemedImage() -> UIImage{
        
        
        // TODO: Hide toobar and navbar
       
        toolBar.isHidden = true
        navigationBar.isHidden = true
        
        //Rendeare view to an image
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.drawHierarchy(in: self.view.frame, afterScreenUpdates: true)
        let memedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        //TODO: Show toobar and navbar
        navigationBar.isHidden = false
        toolBar.isHidden = false
      
        
        return memedImage
    }
 }


