package com.odmlbook.smartreplytestapp

import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import com.google.mlkit.nl.smartreply.SmartReply
import com.google.mlkit.nl.smartreply.SmartReplySuggestionResult
import com.google.mlkit.nl.smartreply.TextMessage

class MainActivity : AppCompatActivity() {
    var outputText = ""
    var conversation : ArrayList<TextMessage> = ArrayList<TextMessage>()
    lateinit var replyButton: Button
    lateinit var txtInput: EditText
    private lateinit var conversationView: TextView
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        conversationView = findViewById(R.id.conversationView)
        txtInput = findViewById(R.id.txtInput)
        initializeConversation()

        replyButton = findViewById(R.id.btnReply)
        replyButton.setOnClickListener {
            val smartReplyGenerator = SmartReply.getClient()
            smartReplyGenerator.suggestReplies(conversation)
                    .addOnSuccessListener { result ->
                        if (result.getStatus() == SmartReplySuggestionResult.STATUS_NOT_SUPPORTED_LANGUAGE) {

                        } else if (result.getStatus() == SmartReplySuggestionResult.STATUS_SUCCESS) {
                            txtInput.setText(result.suggestions[0].text.toString())
                        }
                    }
                    .addOnFailureListener {
                        // Task failed with an exception
                        // ...
                    }
        }
    }

    fun initializeConversation(){
        val friendName: String = "Nizhoni"

        addConversationItem("Hi, good morning!")
        addConversationItem("Oh, hey -- how are you?", friendName)
        addConversationItem("Just got up, thinking of heading out for breakfast")
        addConversationItem("Want to meet up?",friendName)
        addConversationItem("Sure, what do you fancy?")
        addConversationItem("Just coffee, or do you want to eat?", friendName)
        conversationView.text = outputText

    }

    private fun addConversationItem(item: String){
        outputText += "Me : $item\n"
        conversation.add(TextMessage.createForLocalUser(item, System.currentTimeMillis()))
    }

    private fun addConversationItem(item: String, who: String){
        outputText += who + " : " + item + "\n"
        conversation.add(TextMessage.createForRemoteUser(item, System.currentTimeMillis(),who))
    }
}