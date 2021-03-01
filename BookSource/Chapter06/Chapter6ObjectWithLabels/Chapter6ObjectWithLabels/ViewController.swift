//
//  ViewController.swift
//  Chapter6ObjectWithLabels
//
//  Created by Laurence Moroney on 2/23/21.
//

import UIKit
import MLKitVision
import MLKitObjectDetection
import MLKitImageLabeling


class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var dummyImageView: UIImageView!
    @IBAction func btnPress(_ sender: Any) {
        runObjectDetection(with: imageView.image!)
    }
    
    @IBOutlet weak var lblOutput: UILabel!
    var theImage = UIImage(named:"bird.jpg")
    // We'll have a var to hold all the labels
    var labeltexts = ""
    var currentLabel = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = theImage
        imageView.addSubview(annotationOverlayView)
        NSLayoutConstraint.activate([
          annotationOverlayView.topAnchor.constraint(equalTo: imageView.topAnchor),
          annotationOverlayView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
          annotationOverlayView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
          annotationOverlayView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
        ])    }


    /// An overlay view that displays detection annotations.
    private lazy var annotationOverlayView: UIView = {
      precondition(isViewLoaded)
      let annotationOverlayView = UIView(frame: .zero)
      annotationOverlayView.translatesAutoresizingMaskIntoConstraints = false
      return annotationOverlayView
    }()

    func runObjectDetection(with image: UIImage){
        let options = ObjectDetectorOptions()
        options.detectorMode = .singleImage
        options.shouldEnableClassification = true
        options.shouldEnableMultipleObjects = true
        let objectDetector = ObjectDetector.objectDetector(options: options)
        
        let visionImage = VisionImage(image: image)
        visionImage.orientation = image.imageOrientation
        objectDetector.process(visionImage) { detectedObjects, error in
          self.processResult(from: detectedObjects, error: error)
        }
        
    }

    func processResult(from detectedObjects: [Object]?, error: Error?) {
        currentLabel = 0
        guard let detectedObjects = detectedObjects else{
            return
        }
        for obj in detectedObjects{
            currentLabel+=1
            let transform = self.transformMatrix()
            let transformedRect = obj.frame.applying(transform)
            self.addRectangle(
                transformedRect,
                to: self.annotationOverlayView,
                current: currentLabel
            )
            
            guard let cutImageRef: CGImage = theImage?.cgImage?.cropping(to: obj.frame) else {break}
            let croppedImage: UIImage = UIImage(cgImage: cutImageRef)

            let visionImage = VisionImage(image: croppedImage)
            visionImage.orientation = croppedImage.imageOrientation
            let options = ImageLabelerOptions()
            options.confidenceThreshold = 0.8
            let labeler = ImageLabeler.imageLabeler(options: options)
            labeler.process(visionImage) {labels, error in
                self.processLabellingResult(from: labels, error: error)
            }
            
            
        }
    }

    // This gets called by the labeler's callback
    func processLabellingResult(from labels: [ImageLabel]?, error: Error?){
        // Check that we have valid labels first
        guard let labels = labels else{
            return
        }
        // ...and if we do we can iterate through the set to get the description and confidence
        for label in labels{
            let labelText = label.text + " : " + label.confidence.description + "\n"
            self.labeltexts += labelText
        }
        // And when we're done we can update the UI with the list of labels
        self.labeltexts += "\n"
        self.lblOutput.text = self.labeltexts
    }

    private func transformMatrix() -> CGAffineTransform {
      guard let image = imageView.image else { return CGAffineTransform() }
      let imageViewWidth = imageView.frame.size.width
      let imageViewHeight = imageView.frame.size.height
      let imageWidth = image.size.width
      let imageHeight = image.size.height

      let imageViewAspectRatio = imageViewWidth / imageViewHeight
      let imageAspectRatio = imageWidth / imageHeight
      let scale =
        (imageViewAspectRatio > imageAspectRatio)
        ? imageViewHeight / imageHeight : imageViewWidth / imageWidth

      // Image view's `contentMode` is `scaleAspectFit`, which scales the image to fit the size of the
      // image view by maintaining the aspect ratio. Multiple by `scale` to get image's original size.
      let scaledImageWidth = imageWidth * scale
      let scaledImageHeight = imageHeight * scale
      let xValue = (imageViewWidth - scaledImageWidth) / CGFloat(2.0)
      let yValue = (imageViewHeight - scaledImageHeight) / CGFloat(2.0)

      var transform = CGAffineTransform.identity.translatedBy(x: xValue, y: yValue)
      transform = transform.scaledBy(x: scale, y: scale)
      return transform
    }

    private func addRectangle(_ rectangle: CGRect, to view: UIView, current: Int) {
        let rectangleView = UIView(frame: rectangle)
        rectangleView.layer.cornerRadius = 2.0
        rectangleView.layer.borderWidth = 4
        rectangleView.layer.borderColor = UIColor.red.cgColor
        
        let labelView = UILabel(frame: rectangle)
        labelView.text = String(current)
        labelView.textColor = UIColor.black
        labelView.backgroundColor = UIColor.red
        labelView.textAlignment = NSTextAlignment.left
        labelView.numberOfLines = 0
        labelView.sizeToFit()


        view.addSubview(rectangleView)
        view.addSubview(labelView)
        
    }

}

