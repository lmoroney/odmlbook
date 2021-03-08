//
//  ViewController.swift
//  NLPClassifier
//
//  Created by Laurence Moroney on 3/5/21.
//

import UIKit
import TensorFlowLite

class ViewController: UIViewController, UITextViewDelegate {
    @IBOutlet weak var txtInput: UITextView!
    @IBOutlet weak var txtOutput: UILabel!
    @IBAction func classifySentence(_ sender: Any) {
        doClassificationFor(sentence: txtInput.text!)
    }
    var words_dictionary = [String : Int]()
    let SEQUENCE_LENGTH = 20
    let stopwords : [String] = ["a", "about", "above", "after", "again", "against", "all", "am", "an", "and", "any", "are", "as", "at", "be", "because", "been", "before", "being", "below", "between", "both", "but", "by", "could", "did", "do", "does", "doing", "down", "during", "each", "few", "for", "from", "further", "had", "has", "have", "having", "he", "hed", "hes", "her", "here", "heres", "hers", "herself", "him", "himself", "his", "how", "hows", "i", "id", "ill", "im", "ive", "if", "in", "into", "is", "it", "its", "itself", "lets", "me", "more", "most", "my", "myself", "nor", "of", "on", "once", "only", "or", "other", "ought", "our", "ours", "ourselves", "out", "over", "own", "same", "she", "shed", "shell", "shes", "should", "so", "some", "such", "than", "that", "thats", "the", "their", "theirs", "them", "themselves", "then", "there", "theres", "these", "they", "theyd", "theyll", "theyre", "theyve", "this", "those", "through", "to", "too", "under", "until", "up", "very", "was", "we", "wed", "well", "were", "weve", "were", "what", "whats", "when", "whens", "where", "wheres", "which", "while", "who", "whos", "whom", "why", "whys", "with", "would", "you", "youd", "youll", "youre", "youve", "your", "yours", "yourself", "yourselves"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        txtInput.delegate = self
        // Load the vocabulary into a dictionary
        loadVocab()
    }

    // hides Keyboard when user hits enter
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func doClassificationFor(sentence: String){

        // Convert the sente
        let sequence = convert_sentence(sentence: sentence)
        print(sequence)
        classify(sequence: sequence)
    }
    
    func loadVocab(){
        // This func will take the file at vocab.txt and load it into a has table
        // called words_dictionary. This will be used to tokenize the words before passing them
        // to the model trained by TensorFlow Lite Model Maker
        if let filePath = Bundle.main.path(forResource: "vocab", ofType: "txt") {
            do {
                let dictionary_contents = try String(contentsOfFile: filePath)
                let lines = dictionary_contents.split(whereSeparator: \.isNewline)
                for line in lines{
                    let tokens = line.components(separatedBy: " ")
                    let key = String(tokens[0])
                    let value = Int(tokens[1])
                    words_dictionary[key] = value
                }
            } catch {
                print("Error vocab could not be loaded")
            }
        } else {
            print("Error -- vocab file not found")
            
        }
    }
    
    func convert_sentence(sentence: String) -> [Int32]{
        // This func will split a sentence into individual words, while stripping punctuation
        // and will then evaluate each words against stopwords. If it's in the stop words
        // the word will be ignored. If it isn't in the stopwords, then the word will be looked for
        // in the dictionary. If it's there, it's value from the dictionary will be added to
        // the sequence. Otherwise we'll continue
        
        // Initialize the sequence to be all 0s, and the length to be determined
        // by the const SEQUENCE_LENGTH. This should be the same length as the
        // sequences that the model was trained for
        var sequence = [Int32](repeating: 0, count: SEQUENCE_LENGTH)
        
        var words : [String] = []
        sentence.enumerateSubstrings(in: sentence.startIndex..<sentence.endIndex,options: .byWords) {
                                       (substring, _, _, _) -> () in words.append(substring!) }
        var thisWord = 0
        for word in words{
            if (thisWord>=SEQUENCE_LENGTH){
                break
            }
            let seekword = word.lowercased()
            // Alternative code here that uses stopwords
            // TFLMM models don't use them by default, so you
            // don't need this. But if you used stopwords to create
            // a mode you could use this to make a better sequence
            /*
            if !stopwords.contains(seekword){
                if let val = words_dictionary[seekword]{
                    sequence[thisWord]=Int32(val)
                    thisWord = thisWord + 1
                }
            }
            */
            if let val = words_dictionary[seekword]{
                sequence[thisWord]=Int32(val)
                thisWord = thisWord + 1
            }
        }
        return sequence
    }
    
    func classify(sequence: [Int32]){
        // Model Path is the location of the model in the bundle
        let modelPath = Bundle.main.path(forResource: "model", ofType: "tflite")
        var interpreter: Interpreter
        do{
            interpreter = try Interpreter(modelPath: modelPath!)
        } catch _{
            print("Error loading model!")
            return
        }
        let tSequence = Array(sequence)
        let myData = Data(copyingBufferOf: tSequence.map { Int32($0) })
        //var myData = sequence.withUnsafeBufferPointer {Data(buffer: $0)}
        let outputTensor: Tensor
        do {
            // Allocate memory for the model's input `Tensor`s.
            try interpreter.allocateTensors()

            // Copy the RGB data to the input `Tensor`.
            try interpreter.copy(myData, toInputAt: 0)

            // Run inference by invoking the `Interpreter`.
            try interpreter.invoke()

            // Get the output `Tensor` to process the inference results.
            outputTensor = try interpreter.output(at: 0)
            // Turn the output tensor into an array. This will have 2 values
            // Value at index 0 is the probability of negative sentiment
            // Value at index 1 is the probability of positive sentiment
            let resultsArray = outputTensor.data
            let results: [Float32] = [Float32](unsafeData: resultsArray) ?? []
            let negativeSentimentValue = results[0]
            let positiveSentimentValue = results[1]
            var outputString = "Negative Sentiment: " + String(negativeSentimentValue) + "\n"
            outputString = outputString + "Positive Sentiment: " + String(positiveSentimentValue)
            txtOutput.text = outputString

        } catch let error {
            print("Failed to invoke the interpreter with error: \(error.localizedDescription)")
        }
    }
}

extension Data {
  /// Creates a new buffer by copying the buffer pointer of the given array.
  ///
  /// - Warning: The given array's element type `T` must be trivial in that it can be copied bit
  ///     for bit with no indirection or reference-counting operations; otherwise, reinterpreting
  ///     data from the resulting buffer has undefined behavior.
  /// - Parameter array: An array with elements of type `T`.
  init<T>(copyingBufferOf array: [T]) {
    self = array.withUnsafeBufferPointer(Data.init)
  }
}

extension Array {
  /// Creates a new array from the bytes of the given unsafe data.
  ///
  /// - Warning: The array's `Element` type must be trivial in that it can be copied bit for bit
  ///     with no indirection or reference-counting operations; otherwise, copying the raw bytes in
  ///     the `unsafeData`'s buffer to a new array returns an unsafe copy.
  /// - Note: Returns `nil` if `unsafeData.count` is not a multiple of
  ///     `MemoryLayout<Element>.stride`.
  /// - Parameter unsafeData: The data containing the bytes to turn into an array.
  init?(unsafeData: Data) {
    guard unsafeData.count % MemoryLayout<Element>.stride == 0 else { return nil }
    #if swift(>=5.0)
    self = unsafeData.withUnsafeBytes { .init($0.bindMemory(to: Element.self)) }
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

