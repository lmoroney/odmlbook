//
//  ViewController.swift
//  firstFace
//
//  Created by Laurence Moroney on 12/8/20.
//

import UIKit
import MLKitFaceDetection
import MLKitVision

class ViewController: UIViewController {
    @IBAction func buttonPressed(_ sender: Any) {
        runFaceContourDetection(with: imageView.image!)
    }
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        imageView.image = UIImage(named: "face1.jpg")
        imageView.addSubview(annotationOverlayView)
        NSLayoutConstraint.activate([
          annotationOverlayView.topAnchor.constraint(equalTo: imageView.topAnchor),
          annotationOverlayView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
          annotationOverlayView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
          annotationOverlayView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
        ])
        
    }

    private lazy var faceDetectorOption: FaceDetectorOptions = {
      let option = FaceDetectorOptions()
      option.contourMode = .all
      option.performanceMode = .fast
      return option
    }()
    private lazy var faceDetector = FaceDetector.faceDetector(options: faceDetectorOption)
    func runFaceContourDetection(with image: UIImage) {
      let visionImage = VisionImage(image: image)
      visionImage.orientation = image.imageOrientation
      faceDetector.process(visionImage) { features, error in
        self.processResult(from: features, error: error)
      }
    }
    /// 검출된 바운딩박스를 그리기 위한 오버레이 뷰
    private lazy var annotationOverlayView: UIView = {
      precondition(isViewLoaded)
      let annotationOverlayView = UIView(frame: .zero)
      annotationOverlayView.translatesAutoresizingMaskIntoConstraints = false
      return annotationOverlayView
    }()
    
    func processResult(from faces: [Face]?, error: Error?) {
        guard let faces = faces else {
          return
        }
        for feature in faces {
              let transform = self.transformMatrix()
              let transformedRect = feature.frame.applying(transform)
              self.addRectangle(
                transformedRect,
                to: self.annotationOverlayView,
                color: UIColor.green
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

      // 이미지뷰의 `contentMode`는 `scaleAspectFit`로 설됭되어 있습니다.
      // 이 설정은 이미지의 가로 세로 비율은 유지하면서 이미지의 크기를 이미지뷰 크기에 맞춰 조정해라는 옵션입니다.
      // 이미지의 원본 크기를 가져오기위해 `scale`을 곱합니다.
      let scaledImageWidth = imageWidth * scale
      let scaledImageHeight = imageHeight * scale
      let xValue = (imageViewWidth - scaledImageWidth) / CGFloat(2.0)
      let yValue = (imageViewHeight - scaledImageHeight) / CGFloat(2.0)

      var transform = CGAffineTransform.identity.translatedBy(x: xValue, y: yValue)
      transform = transform.scaledBy(x: scale, y: scale)
      return transform
    }
    
    private func addRectangle(_ rectangle: CGRect, to view: UIView, color: UIColor) {
      let rectangleView = UIView(frame: rectangle)
      rectangleView.layer.cornerRadius = 10.0
      rectangleView.alpha = 0.3
      rectangleView.backgroundColor = color
      view.addSubview(rectangleView)
    }
    
}

