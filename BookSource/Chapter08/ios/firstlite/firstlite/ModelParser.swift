//
//  ModelParser.swift
//  firstlite
//
//  Created by Laurence on 2/10/21.
//

import Foundation
import TensorFlowLite

typealias FileInfo = (name: String, extension: String)

enum ModelFile {
  static let modelInfo: FileInfo = (name: "model", extension: "tflite")
}

class ModelParser {

    private var interpreter: Interpreter
    
    init?(modelFileInfo: FileInfo, threadCount: Int = 1) {
        let modelFilename = modelFileInfo.name

        guard let modelPath = Bundle.main.path(
          forResource: modelFilename,
          ofType: modelFileInfo.extension
        ) else {
          print("Failed to load the model file")
          return nil
        }
        do {
            interpreter = try Interpreter(modelPath: modelPath)
        } catch let error
        {
            print("Failed to create the interpreter")
            return nil
        }
    }
    
    func runModel(withInput input: Float) -> Float? {
        do {
            try interpreter.allocateTensors()
            var data: Float = input
            let buffer: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(start: &data, count: 1)
            try interpreter.copy(Data(buffer: buffer), toInputAt: 0)
            try interpreter.invoke()
            let outputTensor = try interpreter.output(at: 0)
            let results: [Float32] =
            [Float32](unsafeData: outputTensor.data) ?? []
            guard let result = results.first else {
              return nil
            }
            return result
        }
        catch {
              print(error)
              return nil
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
