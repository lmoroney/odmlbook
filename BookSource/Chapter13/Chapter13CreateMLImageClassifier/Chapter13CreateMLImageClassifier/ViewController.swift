//
//  ViewController.swift
//  Chapter13CreateMLImageClassifier
//
//  Created by Laurence Moroney on 3/8/21.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController {
    let NUM_CLASSES = 5
    var currentImage = 1
    @IBAction func nextButton(_ sender: Any) {
        currentImage = currentImage + 1
        if currentImage>=7 {
            currentImage = 1
        }
        loadImage()
    }
    
    @IBAction func prevButton(_ sender: Any) {
        currentImage = currentImage - 1
        if currentImage<=0 {
            currentImage = 6
        }
        loadImage()
    }
    @IBAction func classifyButton(_ sender: Any) {
        interpretImage()
    }
    @IBOutlet weak var txtOutput: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        loadImage()
    }
    func loadImage(){
        imageView.image = UIImage(named: String(currentImage))
    }
    func interpretImage(){
        let theImage: UIImage = UIImage(named: String(currentImage))!
        getClassification(for: theImage)
        
    }
    
    func getClassification(for image: UIImage) {
        
        let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue))!
        guard let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image).") }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                try handler.perform([self.classificationRequest])
            } catch {
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }
    
    /// - Tag: MLModelSetup
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel.init(for: flower().model)
            //let model: flower = try! flower(configuration: MLModelConfiguration.init())
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processResults(for: request, error: error)
            })
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()

    func processResults(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results else {
                self.txtOutput.text = "Unable to classify image.\n\(error!.localizedDescription)"
                return
            }
            // The `results` will always be `VNClassificationObservation`s, as specified by the Core ML model in this project.
            let classifications = results as! [VNClassificationObservation]
        
            if classifications.isEmpty {
                self.txtOutput.text = "Nothing recognized."
            } else {
                // Display top classifications ranked by confidence in the UI.
                let topClassifications = classifications.prefix(self.NUM_CLASSES)
                let descriptions = topClassifications.map { classification in
                    // Formats the classification for display; e.g. "(0.37) cliff, drop, drop-off".
                   return String(format: "  (%.2f) %@", classification.confidence, classification.identifier)
                }
                self.txtOutput.text = "Classification:\n" + descriptions.joined(separator: "\n")
            }
        }
    }
}

