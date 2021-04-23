//
//  ViewController.swift
//  MLKitEntityExample
//
//  Created by Laurence Moroney on 3/1/21.
//

import UIKit
import MLKitEntityExtraction

class ViewController: UIViewController, UITextViewDelegate {

    var modelAvailable = false
    var extractorAvailable = false
    var contentString: String = ""
    var entityExtractor = EntityExtractor.entityExtractor(options: EntityExtractorOptions(modelIdentifier: EntityExtractionModelIdentifier.english))
    @IBOutlet weak var txtInput: UITextView!
    @IBOutlet weak var txtOutput: UILabel!
    @IBAction func doExtraction(_ sender: Any) {
        if(modelAvailable){
            extractEntities()
        } else {
            txtOutput.text = "Model not yet downloaded, please try later."
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        entityExtractor.downloadModelIfNeeded(completion: { error in
            guard error == nil else {
                self.txtOutput.text = "Error downloading model, please restart app."
                return
            }
            self.modelAvailable = true
        })
        txtInput.delegate = self
        contentString = "Hi Nizhoni, I'll be at 19 Fifth Avenue in San Jose tomorrow at 5PM where we can discuss my book - 978-1492078197, if you can reach me, call me at 555 213 2121 or email lmoroney@area51.net"
        txtInput.text = contentString
    }
    
    // hides text views
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func extractEntities(){
        let strText = txtInput.text
        entityExtractor.annotateText(
            strText!,
              completion: {
                results, error in
                var strOutput = ""
                for annotation in results! {
                    //print(annotation)
                    for entity in annotation.entities{
                        strOutput += entity.entityType.rawValue + " : "

                        let startLoc = annotation.range.location
                        let endLoc = startLoc + annotation.range.length - 1
                        let mySubString = strText![startLoc...endLoc]
                        
                        strOutput += mySubString + "\n"
                    }
                }
                self.txtOutput.text = strOutput
              }
        )
    }

}

extension String {
  subscript(_ i: Int) -> String {
    let idx1 = index(startIndex, offsetBy: i)
    let idx2 = index(idx1, offsetBy: 1)
    return String(self[idx1..<idx2])
  }

  subscript (r: Range<Int>) -> String {
    let start = index(startIndex, offsetBy: r.lowerBound)
    let end = index(startIndex, offsetBy: r.upperBound)
    return String(self[start ..< end])
  }

  subscript (r: CountableClosedRange<Int>) -> String {
    let startIndex =  self.index(self.startIndex, offsetBy: r.lowerBound)
    let endIndex = self.index(startIndex, offsetBy: r.upperBound - r.lowerBound)
    return String(self[startIndex...endIndex])
  }
}

