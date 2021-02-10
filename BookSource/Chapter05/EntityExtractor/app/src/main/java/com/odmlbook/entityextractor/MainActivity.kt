package com.odmlbook.entityextractor

import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import com.google.mlkit.nl.entityextraction.*
import java.util.*

class MainActivity : AppCompatActivity() {

    val entityExtractor = EntityExtraction.getClient(
            EntityExtractorOptions.Builder(EntityExtractorOptions.ENGLISH)
                    .build())
    var extractorAvailable:Boolean = false
    lateinit var txtInput: EditText
    lateinit var txtOutput: TextView
    lateinit var btnExtract: Button
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        txtInput = findViewById(R.id.txtInput)
        txtOutput = findViewById(R.id.txtOutput)
        btnExtract = findViewById(R.id.btnExtract)
        prepareExtractor()
        btnExtract.setOnClickListener {
            doExtraction()
        }
    }

    fun prepareExtractor(){
        entityExtractor.downloadModelIfNeeded().addOnSuccessListener {
            extractorAvailable = true
        }
        .addOnFailureListener {
            extractorAvailable = false
        }
    }

    fun doExtraction(){
        if (extractorAvailable) {
            val userText = txtInput.text.toString()
            val params = EntityExtractionParams.Builder(userText)
                .build()

            var outputString = ""
            entityExtractor.annotate(params)
                .addOnSuccessListener { result: List<EntityAnnotation> ->
                    for (entityAnnotation in result) {
                        outputString += entityAnnotation.annotatedText
                        for (entity in entityAnnotation.entities) {
                            outputString += ":" + getStringFor(entity)
                        }
                        outputString += "\n\n"
                    }
                    txtOutput.text = outputString
                }
                .addOnFailureListener {

                }
        }


    }

    private fun getStringFor(entity: Entity): String{
        var returnVal = "Type - "
        when (entity.type) {
            Entity.TYPE_ADDRESS -> returnVal += "Address"
            Entity.TYPE_DATE_TIME -> returnVal += "DateTime"
            Entity.TYPE_EMAIL -> returnVal += "Email Address"
            Entity.TYPE_FLIGHT_NUMBER -> returnVal += "Flight Number"
            Entity.TYPE_IBAN -> returnVal += "IBAN"
            Entity.TYPE_ISBN -> returnVal += "ISBN"
            Entity.TYPE_MONEY -> returnVal += "Money"
            Entity.TYPE_PAYMENT_CARD -> returnVal += "Credit/Debit Card"
            Entity.TYPE_PHONE -> returnVal += "Phone Number"
            Entity.TYPE_TRACKING_NUMBER -> returnVal += "Tracking Number"
            Entity.TYPE_URL -> returnVal += "URL"
            else -> returnVal += "Address"
        }
        return returnVal


    }
}