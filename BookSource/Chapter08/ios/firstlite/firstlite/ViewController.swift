//
//  ViewController.swift
//  firstlite
//
//  Created by Laurence on 2/10/21.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var txtUserData: UITextField!
    @IBOutlet weak var txtResult: UILabel!
    @IBAction func btnGo(_ sender: Any) {
        doInference()
    }
    
    private var modelParser : ModelParser? = ModelParser(modelFileInfo: ModelFile.modelInfo)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    private func doInference(){
        guard let text = txtUserData.text, text.count>0 else{
            txtResult.text = "0.00"
            return
        }
        guard let value = Float(text) else{
            return
        }
        guard let result = self.modelParser?.runModel(withInput: value) else{
            return
        }
        txtResult.text = String(format: "%.2f", result)
        
    }


}

