//
//  ViewController.swift
//  Chapter6ObjectTracking
//
//  Created by Laurence Moroney on 4/23/21.
//

import UIKit
import AVFoundation
import CoreVideo
import MLKit

class ViewController: UIViewController {
    private var isUsingFrontCamera = false
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private lazy var captureSession = AVCaptureSession()
    private lazy var sessionQueue = DispatchQueue(label: "com.google.mlkit.visiondetector.SessionQueue")
    private var lastFrame: CMSampleBuffer?
    @IBOutlet weak var cameraView: UIView!
    private lazy var previewOverlayView: UIImageView = {
      precondition(isViewLoaded)
      let previewOverlayView = UIImageView(frame: .zero)
      previewOverlayView.contentMode = UIView.ContentMode.scaleAspectFill
      previewOverlayView.translatesAutoresizingMaskIntoConstraints = false
      return previewOverlayView
    }()

    private lazy var annotationOverlayView: UIView = {
      precondition(isViewLoaded)
      let annotationOverlayView = UIView(frame: .zero)
      annotationOverlayView.translatesAutoresizingMaskIntoConstraints = false
      return annotationOverlayView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        setUpPreviewOverlayView()
        setUpAnnotationOverlayView()
        setUpCaptureSessionOutput()
        setUpCaptureSessionInput()
    }
    
    private func detectObjectsOnDevice(
      in image: VisionImage,
      width: CGFloat,
      height: CGFloat,
      options: CommonObjectDetectorOptions
    ) {
      let detector = ObjectDetector.objectDetector(options: options)
      var objects: [Object]
      do {
        objects = try detector.results(in: image)
      } catch let error {
        print("Failed to detect objects with error: \(error.localizedDescription).")
        return
      }
      weak var weakSelf = self
      DispatchQueue.main.sync {
        guard let strongSelf = weakSelf else {
          print("Self is nil!")
          return
        }
        strongSelf.updatePreviewOverlayViewWithLastFrame()
        strongSelf.removeDetectionAnnotations()
      }
      guard !objects.isEmpty else {
        print("On-Device object detector returned no results.")
        return
      }

      DispatchQueue.main.sync {
        guard let strongSelf = weakSelf else {
          print("Self is nil!")
          return
        }
        for object in objects {
          let normalizedRect = CGRect(
            x: object.frame.origin.x / width,
            y: object.frame.origin.y / height,
            width: object.frame.size.width / width,
            height: object.frame.size.height / height
          )
          let standardizedRect = strongSelf.previewLayer.layerRectConverted(
            fromMetadataOutputRect: normalizedRect
          ).standardized
          UIUtilities.addRectangle(
            standardizedRect,
            to: strongSelf.annotationOverlayView,
            color: UIColor.green
          )
          let label = UILabel(frame: standardizedRect)
          var description = ""
          if let trackingID = object.trackingID {
            description += "Object ID: " + trackingID.stringValue + "\n"
          }
          description += object.labels.enumerated().map { (index, label) in
            "Label \(index): \(label.text), \(label.confidence), \(label.index)"
          }.joined(separator: "\n")

          label.text = description
          label.numberOfLines = 0
          label.adjustsFontSizeToFitWidth = true
          strongSelf.annotationOverlayView.addSubview(label)
        }
      }
    }
    
    override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(animated)
      startSession()
    }

    override func viewDidDisappear(_ animated: Bool) {
      super.viewDidDisappear(animated)
      stopSession()
    }
    
    private func startSession() {
      weak var weakSelf = self
      sessionQueue.async {
        guard let strongSelf = weakSelf else {
          print("Self is nil!")
          return
        }
        strongSelf.captureSession.startRunning()
      }
    }

    private func stopSession() {
      weak var weakSelf = self
      sessionQueue.async {
        guard let strongSelf = weakSelf else {
          print("Self is nil!")
          return
        }
        strongSelf.captureSession.stopRunning()
      }
    }
    
    override func viewDidLayoutSubviews() {
      super.viewDidLayoutSubviews()
      previewLayer.frame = cameraView.frame
    }
    
    private func setUpPreviewOverlayView() {
      cameraView.addSubview(previewOverlayView)
      NSLayoutConstraint.activate([
        previewOverlayView.centerXAnchor.constraint(equalTo: cameraView.centerXAnchor),
        previewOverlayView.centerYAnchor.constraint(equalTo: cameraView.centerYAnchor),
        previewOverlayView.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor),
        previewOverlayView.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor),

      ])
    }

    private func setUpAnnotationOverlayView() {
      cameraView.addSubview(annotationOverlayView)
      NSLayoutConstraint.activate([
        annotationOverlayView.topAnchor.constraint(equalTo: cameraView.topAnchor),
        annotationOverlayView.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor),
        annotationOverlayView.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor),
        annotationOverlayView.bottomAnchor.constraint(equalTo: cameraView.bottomAnchor),
      ])
    }
    
    private func setUpCaptureSessionOutput() {
      weak var weakSelf = self
      sessionQueue.async {
        guard let strongSelf = weakSelf else {
          print("Self is nil!")
          return
        }
        strongSelf.captureSession.beginConfiguration()
        // When performing latency tests to determine ideal capture settings,
        // run the app in 'release' mode to get accurate performance metrics
        strongSelf.captureSession.sessionPreset = AVCaptureSession.Preset.medium

        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
          (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA
        ]
        output.alwaysDiscardsLateVideoFrames = true
        let outputQueue = DispatchQueue(label: "com.google.mlkit.visiondetector.VideoDataOutputQueue")
        output.setSampleBufferDelegate(strongSelf, queue: outputQueue)
        guard strongSelf.captureSession.canAddOutput(output) else {
          print("Failed to add capture session output.")
          return
        }
        strongSelf.captureSession.addOutput(output)
        strongSelf.captureSession.commitConfiguration()
      }
    }
    
    private func setUpCaptureSessionInput() {
      weak var weakSelf = self
      sessionQueue.async {
        guard let strongSelf = weakSelf else {
          print("Self is nil!")
          return
        }
        //let cameraPosition: AVCaptureDevice.Position = strongSelf.isUsingFrontCamera ? .front : .back
        let cameraPosition: AVCaptureDevice.Position = .back
        guard let device = strongSelf.captureDevice(forPosition: cameraPosition) else {
          print("Failed to get capture device for camera position: \(cameraPosition)")
          return
        }
        do {
          strongSelf.captureSession.beginConfiguration()
          let currentInputs = strongSelf.captureSession.inputs
          for input in currentInputs {
            strongSelf.captureSession.removeInput(input)
          }

          let input = try AVCaptureDeviceInput(device: device)
          guard strongSelf.captureSession.canAddInput(input) else {
            print("Failed to add capture session input.")
            return
          }
          strongSelf.captureSession.addInput(input)
          strongSelf.captureSession.commitConfiguration()
        } catch {
          print("Failed to create capture device input: \(error.localizedDescription)")
        }
      }
    }
    
    private func captureDevice(forPosition position: AVCaptureDevice.Position) -> AVCaptureDevice? {
      if #available(iOS 10.0, *) {
        let discoverySession = AVCaptureDevice.DiscoverySession(
          deviceTypes: [.builtInWideAngleCamera],
          mediaType: .video,
          position: .unspecified
        )
        return discoverySession.devices.first { $0.position == position }
      }
      return nil
    }
    
    private func updatePreviewOverlayViewWithLastFrame() {
      guard let lastFrame = lastFrame,
        let imageBuffer = CMSampleBufferGetImageBuffer(lastFrame)
      else {
        return
      }
      self.updatePreviewOverlayViewWithImageBuffer(imageBuffer)
    }
    
    private func updatePreviewOverlayViewWithImageBuffer(_ imageBuffer: CVImageBuffer?) {
      guard let imageBuffer = imageBuffer else {
        return
      }
      let orientation: UIImage.Orientation = isUsingFrontCamera ? .leftMirrored : .right
      let image = UIUtilities.createUIImage(from: imageBuffer, orientation: orientation)
      previewOverlayView.image = image
    }
    
    private func removeDetectionAnnotations() {
      for annotationView in annotationOverlayView.subviews {
        annotationView.removeFromSuperview()
      }
    }
    
    private func rotate(_ view: UIView, orientation: UIImage.Orientation) {
      var degree: CGFloat = 0.0
      switch orientation {
      case .up, .upMirrored:
        degree = 90.0
      case .rightMirrored, .left:
        degree = 180.0
      case .down, .downMirrored:
        degree = 270.0
      case .leftMirrored, .right:
        degree = 0.0
      }
      view.transform = CGAffineTransform.init(rotationAngle: degree * 3.141592654 / 180)
    }
    
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

  func captureOutput(_ output: AVCaptureOutput,didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      print("Failed to get image buffer from sample buffer.")
      return
    }
    // Evaluate `self.currentDetector` once to ensure consistency throughout this method since it
    // can be concurrently modified from the main thread.
    //let activeDetector = self.currentDetector
    //resetManagedLifecycleDetectors(activeDetector: activeDetector)

    lastFrame = sampleBuffer
    let visionImage = VisionImage(buffer: sampleBuffer)
    let orientation = UIUtilities.imageOrientation(
        fromDevicePosition: .back
    )

    visionImage.orientation = orientation
    let imageWidth = CGFloat(CVPixelBufferGetWidth(imageBuffer))
    let imageHeight = CGFloat(CVPixelBufferGetHeight(imageBuffer))
    let shouldEnableClassification = false
    let shouldEnableMultipleObjects = true
    let options = ObjectDetectorOptions()
    options.shouldEnableClassification = shouldEnableClassification
    options.shouldEnableMultipleObjects = shouldEnableMultipleObjects
    detectObjectsOnDevice(
        in: visionImage,
        width: imageWidth,
        height: imageHeight,
        options: options)
    }
}
