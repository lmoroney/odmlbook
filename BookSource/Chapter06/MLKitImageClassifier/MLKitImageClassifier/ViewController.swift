//
//  ViewController.swift
//  MLKitImageClassifier
//
//  Created by Laurence Moroney on 2/28/21.
//

import UIKit
// Import the MLKit Vision and Image Labeling libraries
import MLKitVision
import MLKitImageLabeling

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var lblOutput: UILabel!
    
    @IBAction func doInference(_ sender: Any) {
        getLabels(with: imageView.image!)
    }
    // On view did load we only need to initialize the image, so we can do that here
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        imageView.image = UIImage(named:"fig6-1dog.jpg")
    }

    // This is called when the user presses the button
    func getLabels(with image: UIImage){
        // Get the image from the UI Image element and set its orientation
        let visionImage = VisionImage(image: image)
        visionImage.orientation = image.imageOrientation
        
        // Create Image Labeler options, and set the threshold to 0.4
        // so we will ignore all classes with a probability of 0.4 or less
        let options = ImageLabelerOptions()
        options.confidenceThreshold = 0.4
        
        // Initialize the labeler with these options
        let labeler = ImageLabeler.imageLabeler(options: options)
        
        // And then process the image, with the callback going to self.processresult
        labeler.process(visionImage) { labels, error in
            self.processResult(from: labels, error: error)
     }
    }
    
    // This gets called by the labeler's callback
    func processResult(from labels: [ImageLabel]?, error: Error?){
        // String to hold the labels
        var labeltexts = ""
        // Check that we have valid labels first
        guard let labels = labels else{
            return
        }
        // ...and if we do we can iterate through the set to get the description and confidence
        for label in labels{
            let labelText = label.text + " : " + label.confidence.description + "\n"
            labeltexts += labelText
        }
        // And when we're done we can update the UI with the list of labels
        lblOutput.text = labeltexts
    }
}

