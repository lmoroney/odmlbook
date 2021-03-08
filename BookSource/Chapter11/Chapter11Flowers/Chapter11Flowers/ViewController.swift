//
//  ViewController.swift
//  Chapter11Flowers
//
//  Created by Laurence Moroney on 3/4/21.
//

import UIKit
import TensorFlowLite


class ViewController: UIViewController{
    // Class Variables
    // Model Path is the location of the model in the bundle
    let modelPath = Bundle.main.path(forResource: "flowers_model", ofType: "tflite")
    // currentImage is used to track/change the image by pressing the prev/next buttons
    var currentImage = 1
    // Hard coding the labels for now. This should be changed to load the labels from the provided metadata
    private var labels: [String] = ["Daisy", "Dandelion", "Rose", "Sunflower", "Tulip"]
    
    // Outlets and Actions section
    // The output label
    @IBOutlet weak var lblOutput: UILabel!
    // The image view to render the picture
    @IBOutlet weak var imageView: UIImageView!
    
    // The previous button changes the value of the current image. If it's <=0, set it to 6 (we have 6 images)
    @IBAction func prevButton(_ sender: Any) {
        currentImage = currentImage - 1
        if currentImage<=0 {
            currentImage = 6
        }
        loadImage()
    }
    // The next button changes the value of the current image. If it's >=7, set it to 1 (we have 6 images)
    @IBAction func nextButton(_ sender: Any) {
        currentImage = currentImage + 1
        if currentImage>=7 {
            currentImage = 1
        }
        loadImage()
    }
    @IBAction func classifyButton(_ sender: Any) {
        interpretImage()
    }


    // Class methods
    // Viewdidload should initialize and load the first image
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        loadImage()
    }
    // The load image function takes the image from the bundle. The name within the bundle is just "1", "2" etc
    // so all you need to do is UIImage(named: "1") etc. -- so String(currentImage) will do the trick
    func loadImage(){
        imageView.image = UIImage(named: String(currentImage))
    }
    
    func getRGBDataFromImage()->Data{
        let image = UIImage(named: String(currentImage))
        var pixelBuffer:CVPixelBuffer
        pixelBuffer = image!.pixelBuffer()!

        // Crops the image to the biggest square in the center and scales it down to model dimensions.
        let scaledSize = CGSize(width: 224, height: 224)
        let thumbnailPixelBuffer = pixelBuffer.centerThumbnail(ofSize: scaledSize)
        // Remove the alpha component from the image buffer to get the RGB data.
        let rgbData = rgbDataFromBuffer(thumbnailPixelBuffer!, byteCount: 1 * 224 * 224 * 3)
        return rgbData!
    }
    
    func getLabelForData(data: Data, interpreter: Interpreter)->String{
    var strReturn = "No Inference"
    let outputTensor: Tensor
    do {
        // Allocate memory for the model's input `Tensor`s.
        try interpreter.allocateTensors()

        // Copy the RGB data to the input `Tensor`.
        try interpreter.copy(data, toInputAt: 0)

        // Run inference by invoking the `Interpreter`.
        try interpreter.invoke()

        // Get the output `Tensor` to process the inference results.
        outputTensor = try interpreter.output(at: 0)

        // Turn the output tensor into an array. This will have 5 values
        // corresponding to the probabilities for the 5 labels
        let resultsArray = outputTensor.data.toArray(type: Float32.self)
        // Pick the biggest value in the array
        let maxVal = resultsArray.max()
        // Get the index of the biggest value
        let resultsIndex = resultsArray.firstIndex(of: maxVal!)
        // Set the result to be the label at that index
        let outputString = labels[resultsIndex!]
        // And set the return val accordingly
        strReturn = outputString
    } catch let error {
        print("Failed to invoke the interpreter with error: \(error.localizedDescription)")
    }

    return strReturn
        
    }
    func interpretImage(){
        var interpreter: Interpreter
        do{
            interpreter = try Interpreter(modelPath: modelPath!)
        } catch _{
            print("Error loading model!")
            return
        }
        let rgbData = getRGBDataFromImage()
        let label = getLabelForData(data:rgbData, interpreter:interpreter)
        lblOutput.text = label

    }
    private func rgbDataFromBuffer(_ buffer: CVPixelBuffer, byteCount: Int) -> Data? {
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        guard let mutableRawPointer = CVPixelBufferGetBaseAddress(buffer) else {
          return nil
        }
        let count = CVPixelBufferGetDataSize(buffer)
        let bufferData = Data(bytesNoCopy: mutableRawPointer, count: count, deallocator: .none)
        var rgbBytes = [Float](repeating: 0, count: byteCount)
        var index = 0
        for component in bufferData.enumerated() {
          let offset = component.offset
          let isAlphaComponent = (offset % 4) == 3
          guard !isAlphaComponent else { continue }
          rgbBytes[index] = Float(component.element) / 255.0
          index += 1
        }
        
        return rgbBytes.withUnsafeBufferPointer(Data.init)

      }
}


