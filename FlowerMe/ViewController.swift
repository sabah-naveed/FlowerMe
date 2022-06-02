//  SABrain
//  ViewController.swift
//  FlowerMe
//
//  Created by Sabah Naveed on 5/31/22.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    
    @IBOutlet weak var imageView: UIImageView!
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            imageView.image = userPickedImage //image user picks
            
            guard let convertedciimage = CIImage(image: userPickedImage) else {
                fatalError("could not convert to ciimage")
            } //converted into ciimage
            detect(image: convertedciimage)
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    @IBAction func cameraClicked(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    func requestInfo(flowerName: String){
        
        let parameters : [String:String] = [
          "format" : "json",
          "action" : "query",
          "prop" : "extracts",
          "exintro" : "",
          "explaintext" : "",
          "titles" : flowerName,
          "indexpageids" : "",
          "redirects" : "1",
          ]
        
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { response in
            if response.result.isSuccess{
                print("got wikipedia info")
                print(JSON(response.result.value))
                
                let flowerJSON: JSON = JSON(response.result.value)
                
                let pageid = flowerJSON["query"]["pageids"][0].string
                
                let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].string
            }
        }
    }
    
    func detect(image: CIImage){
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("loading coreml model failed")
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("model failed to process image")}
            print(results)
            
            if let firstresult = results.first {
                print(firstresult.identifier)
                self.navigationItem.title = firstresult.identifier.capitalized
                self.requestInfo(flowerName: firstresult.identifier)
                
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
}

