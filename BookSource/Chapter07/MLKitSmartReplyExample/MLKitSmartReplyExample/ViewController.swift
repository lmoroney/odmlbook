//
//  ViewController.swift
//  MLKitSmartReplyExample
//
//  Created by Laurence Moroney on 3/2/21.
//

import UIKit
import MLKit

class ViewController: UIViewController {
    var conversation: [TextMessage] = []
    var outputText = ""
    @IBOutlet weak var conversationLabel: UILabel!
    @IBOutlet weak var txtSuggestions: UILabel!
    
    @IBAction func generateReply(_ sender: Any) {
        getSmartReply()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        initializeConversation()
        
    }
    
    private func initializeConversation(){
        let friendName = "Nizhoni"
        addConversationItem(item: "Hi, good morning!")
        addConversationItem(item: "Oh, hey -- how are you?", fromUser: friendName)
        addConversationItem(item: "Just got up, thinking of heading out for breakfast")
        addConversationItem(item: "Want to meet up?", fromUser: friendName)
        addConversationItem(item: "Sure, what do you fancy?")
        addConversationItem(item: "Just coffee, or do you want to eat?", fromUser: friendName)
        conversationLabel.text = outputText

    }
    
    private func addConversationItem(item: String){
        outputText += "Me : \(item)\n"
        let message = TextMessage(text: item, timestamp:Date().timeIntervalSince1970, userID: "Me", isLocalUser: true)
        
        conversation.append(message)
    }
    
    private func addConversationItem(item: String, fromUser: String){
        outputText += "\(fromUser) : \(item)\n"
        let message = TextMessage(text: item, timestamp:Date().timeIntervalSince1970, userID: fromUser, isLocalUser: false)
        
        conversation.append(message)
    }
    
    private func getSmartReply(){
        SmartReply.smartReply().suggestReplies(for: conversation) { result, error in
            guard error == nil, let result = result else {
                return
            }
            print(result.status)
            var strSuggestedReplies = "Suggested Replies:"
            if (result.status == .notSupportedLanguage) {
                // The conversation's language isn't supported, so
                // the result doesn't contain any suggestions.
            } else if (result.status == .success) {
                // Successfully suggested smart replies.
                for suggestion in result.suggestions {
                    strSuggestedReplies = strSuggestedReplies + suggestion.text + "\n"
                }
            }
            self.txtSuggestions.text = strSuggestedReplies
        }
    }

}

