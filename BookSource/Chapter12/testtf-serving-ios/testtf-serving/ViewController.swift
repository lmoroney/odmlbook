//
//  ViewController.swift
//  testtf-serving
//
//  Created by Laurence on 2/21/21.
//

import UIKit

struct Results: Decodable {
  let predictions: [[Double]]
}

class ViewController: UIViewController {

    @IBOutlet weak var txtOutput: UILabel!
    @IBOutlet weak var txtInput: UITextField!
    @IBAction func btnClick(_ sender: Any) {
        let inputVal: Double =  Double(txtInput.text!)!
        doInference(value: inputVal)
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    func doInference(value:Double){
        let json: [String: Any] = ["signature_name" : "serving_default", "instances" : [[value]]]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)

        // create post request
        let url = URL(string: "http://192.168.86.26:8501/v1/models/helloworld:predict")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // insert json data to the request
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let results: Results = try! JSONDecoder().decode(Results.self, from: data)
            print(results.predictions[0][0])
            DispatchQueue.main.async{
                self.txtOutput.text = String(results.predictions[0][0])
            }
        }

        task.resume()
        
    }
}

