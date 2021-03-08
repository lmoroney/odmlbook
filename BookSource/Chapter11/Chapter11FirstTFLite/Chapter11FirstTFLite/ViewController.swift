//
//  ViewController.swift
//  Chapter11FirstTFLite
//
//  Created by Laurence Moroney on 3/6/21.
//

import UIKit
import TensorFlowLite

class ViewController: UIViewController {

    @IBAction func btnInfer(_ sender: Any) {
        doInference()
    }
    @IBOutlet weak var txtOutput: UILabel!
    @IBOutlet weak var txtInput: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    func doInference(){
        var data: Float
        let modelPath = Bundle.main.path(forResource: "model", ofType: "tflite")
        var interpreter: Interpreter
        do{
            interpreter = try Interpreter(modelPath: modelPath!)
        } catch _{
            print("Error loading model!")
            return
        }
        do{
            let inVal = Float(txtInput.text!)
            data = inVal!
            try interpreter.allocateTensors()
            let buffer: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(start: &data, count: 1)
            try interpreter.copy(Data(buffer: buffer), toInputAt: 0)
            try interpreter.invoke()
            let outputTensor = try interpreter.output(at: 0)
            let results: [Float32] = [Float32](unsafeData: outputTensor.data) ?? []
            txtOutput.text = results.description
            return
          }
        catch {
          print(error)
          return
        }
    }
}

extension Array {
  init?(unsafeData: Data) {
    guard unsafeData.count % MemoryLayout<Element>.stride == 0
          else { return nil }
    #if swift(>=5.0)
    self = unsafeData.withUnsafeBytes {
      .init($0.bindMemory(to: Element.self))
    }
    #else
    self = unsafeData.withUnsafeBytes {
      .init(UnsafeBufferPointer<Element>(
        start: $0,
        count: unsafeData.count / MemoryLayout<Element>.stride
      ))
    }
    #endif  // swift(>=5.0)
  }
}


    


