//
//  ViewController.swift
//  Chapter13Emotion
//
//  Created by Laurence Moroney on 3/9/21.
//

import UIKit
import NaturalLanguage
import CoreML

class ViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var txtInput: UITextView!
    @IBOutlet weak var txtOutput: UILabel!
    @IBAction func classifyText(_ sender: Any) {
        doInference()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        txtInput.delegate = self
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func doInference(){
        do{
            let mlModel = try emotion(configuration: MLModelConfiguration()).model
            let sentimentPredictor = try NLModel(mlModel: mlModel)
            let inputText = txtInput.text
            let label = sentimentPredictor.predictedLabel(for: inputText!)
            if (label=="0"){
                txtOutput.text = "Sentiment: Negative"
            } else {
                txtOutput.text = "Sentiment: Positive"
            }
        print(label)
        } catch {
            print(error)
        }
    }
}

