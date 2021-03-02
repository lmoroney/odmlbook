//
//  ViewController.swift
//  MLKitInkExample
//
//  Created by Laurence Moroney on 3/1/21.
//

import UIKit
import MLKit

class ViewController: UIViewController {

    @IBAction func recognizeInk(_ sender: Any) {
        doRecognition()
    }
    
    @IBOutlet weak var mainImageView: UIImageView!
    var lastPoint = CGPoint.zero
    var color = UIColor.white
    var brushWidth: CGFloat = 10.0
    var opacity: CGFloat = 1.0
    private var strokes: [Stroke] = []
    private var points: [StrokePoint] = []
    private var recognizer: DigitalInkRecognizer! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        initModel()
    }
    func drawLine(from fromPoint: CGPoint, to toPoint: CGPoint) {
      UIGraphicsBeginImageContext(view.frame.size)
      guard let context = UIGraphicsGetCurrentContext() else {
        return
      }
      mainImageView.image?.draw(in: view.bounds)
      
      context.move(to: fromPoint)
      context.addLine(to: toPoint)
      
      context.setLineCap(.round)
      context.setBlendMode(.normal)
      context.setLineWidth(brushWidth)
      context.setStrokeColor(color.cgColor)
      
      context.strokePath()
      
        mainImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        mainImageView.alpha = opacity
      
      UIGraphicsEndImageContext()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        lastPoint = touch.location(in: mainImageView)
        let t = touch.timestamp
        points = [StrokePoint.init(x: Float(lastPoint.x), y: Float(lastPoint.y), t: Int(t * 1000))]
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let currentPoint = touch.location(in: mainImageView)
        let t = touch.timestamp
        points.append(StrokePoint.init(x: Float(currentPoint.x), y: Float(currentPoint.y), t: Int(t * 1000)))
        drawLine(from: lastPoint, to: currentPoint)
        lastPoint = currentPoint
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let t = touch.timestamp
        points.append(StrokePoint.init(x: Float(lastPoint.x), y: Float(lastPoint.y), t: Int(t * 1000)))
        strokes.append(Stroke.init(points: points))
        drawLine(from: lastPoint, to: lastPoint)
    }
    
    func initModel(){
        let languageTag = "en-US"
        let identifier = DigitalInkRecognitionModelIdentifier(forLanguageTag: languageTag)
        if identifier == nil {
          // no model was found or the language tag couldn't be parsed, handle error.
        }
        let model = DigitalInkRecognitionModel.init(modelIdentifier: identifier!)
        var modelManager = ModelManager.modelManager()
        modelManager.download(model, conditions: ModelDownloadConditions.init(allowsCellularAccess: true, allowsBackgroundDownloading: true))
        // Get a recognizer for the language
        let options: DigitalInkRecognizerOptions = DigitalInkRecognizerOptions.init(model: model)
        recognizer = DigitalInkRecognizer.digitalInkRecognizer(options: options)
    }
    
    func doRecognition(){
        // Specify the recognition model for a language
        var alertTitle = ""
        var alertText = ""
        let ink = Ink.init(strokes: strokes)
        recognizer.recognize(
          ink: ink,
          completion: {
            (result: DigitalInkRecognitionResult?, error: Error?) in
            if let result = result, let candidate = result.candidates.first {
                alertTitle = "I recognized this:"
                alertText = candidate.text
            } else {
                alertTitle = "I hit an error:"
                alertText = error!.localizedDescription
            }
            let alert = UIAlertController(title: alertTitle, message: alertText, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            self.mainImageView.image = nil
            self.strokes = []
            self.points = []
          })

        
    }

}

