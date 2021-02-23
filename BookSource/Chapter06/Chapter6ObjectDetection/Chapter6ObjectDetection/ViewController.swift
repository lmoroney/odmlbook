//
//  ViewController.swift
//  Chapter6ObjectDetection
//
//  Created by Laurence Moroney on 2/22/21.
//

import UIKit
import MLKitVision
import MLKitObjectDetection
class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!

    @IBAction func btnPressed(_ sender: Any) {
        runObjectDetection(with: imageView.image!)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        imageView.image = UIImage(named: "bird.jpg")
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
    
    func processResult(from detectedObjects: [Object]?, error: Error?){
        guard let detectedObjects = detectedObjects else{
            return
        }
        for obj in detectedObjects{
            let transform = self.transformMatrix()
            let transformedRect = obj.frame.applying(transform)
            self.addRectangle(
              transformedRect,
              to: self.annotationOverlayView
                
            )
        }
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
    
    private func addRectangle(_ rectangle: CGRect, to view: UIView) {
        let rectangleView = UIView(frame: rectangle)
        rectangleView.layer.cornerRadius = 2.0
        rectangleView.layer.borderWidth = 4
        rectangleView.layer.borderColor = UIColor.red.cgColor

        view.addSubview(rectangleView)
    }


}

