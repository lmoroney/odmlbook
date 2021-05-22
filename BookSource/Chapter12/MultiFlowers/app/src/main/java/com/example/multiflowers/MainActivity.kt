package com.example.multiflowers

import android.graphics.drawable.BitmapDrawable
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.ImageView
import android.widget.Toast
import com.google.firebase.ml.modeldownloader.CustomModel
import com.google.firebase.ml.modeldownloader.CustomModelDownloadConditions
import com.google.firebase.ml.modeldownloader.DownloadType
import com.google.firebase.ml.modeldownloader.FirebaseModelDownloader
import com.google.firebase.remoteconfig.FirebaseRemoteConfig
import com.google.firebase.remoteconfig.FirebaseRemoteConfigSettings
import org.tensorflow.lite.support.image.TensorImage
import org.tensorflow.lite.task.vision.classifier.Classifications
import org.tensorflow.lite.task.vision.classifier.ImageClassifier
import java.io.File

class MainActivity : AppCompatActivity(), View.OnClickListener {
    lateinit var imageClassifier: ImageClassifier
    lateinit var modelName:String
    lateinit var mFirebaseRemoteConfig:FirebaseRemoteConfig
    var modelReady: Boolean = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        initializeModelFromRemoteConfig()
    }

    private fun initViews() {
        findViewById<ImageView>(R.id.iv_1).setOnClickListener(this)
        findViewById<ImageView>(R.id.iv_2).setOnClickListener(this)
        findViewById<ImageView>(R.id.iv_3).setOnClickListener(this)
        findViewById<ImageView>(R.id.iv_4).setOnClickListener(this)
        findViewById<ImageView>(R.id.iv_5).setOnClickListener(this)
        findViewById<ImageView>(R.id.iv_6).setOnClickListener(this)
    }

    private fun loadModel(){
        val conditions = CustomModelDownloadConditions.Builder()
            .requireWifi()  // Also possible: .requireCharging() and .requireDeviceIdle()
            .build()
        FirebaseModelDownloader.getInstance()
            .getModel(modelName, DownloadType.LOCAL_MODEL_UPDATE_IN_BACKGROUND,
                conditions)
            .addOnSuccessListener { model: CustomModel ->
                val modelFile: File? = model.file
                if (modelFile != null) {
                    val options: ImageClassifier.ImageClassifierOptions = ImageClassifier.ImageClassifierOptions.builder().setMaxResults(1).build()
                    imageClassifier = ImageClassifier.createFromFileAndOptions(modelFile, options)
                    modelReady = true
                    runOnUiThread { Toast.makeText(this, "Model is now ready!", Toast.LENGTH_SHORT).show() }
                }

            }
    }

    override fun onClick(view: View?) {
        var outp:String = ""
        if(modelReady){
            val bitmap = ((view as ImageView).drawable as BitmapDrawable).bitmap
            val image = TensorImage.fromBitmap(bitmap)
            val results:List<Classifications> = imageClassifier.classify(image)
            val label = results[0].categories[0].label
            val score = results[0].categories[0].score
            outp = "I see $label with confidence $score"
        } else {
            outp = "Model not yet ready, please wait or restart the app."
        }

        runOnUiThread { Toast.makeText(this, outp, Toast.LENGTH_SHORT).show() }

    }

    private fun initializeModelFromRemoteConfig(){
        mFirebaseRemoteConfig = FirebaseRemoteConfig.getInstance()
        val configSettings = FirebaseRemoteConfigSettings.Builder()
                .setMinimumFetchIntervalInSeconds(3600)
                .build()
        mFirebaseRemoteConfig.setConfigSettingsAsync(configSettings)
        mFirebaseRemoteConfig.fetchAndActivate()
                .addOnCompleteListener(this) { task ->
                    if (task.isSuccessful) {
                        val updated = task.result
                        Log.d("Flowers", "Config params updated: $updated")
                        Toast.makeText(this@MainActivity, "Fetch and activate succeeded",
                                Toast.LENGTH_SHORT).show()
                        modelName = mFirebaseRemoteConfig.getString("model_name")
                        loadModel()
                        initViews()
                    } else {
                        Toast.makeText(this@MainActivity, "Fetch failed - using default value",
                                Toast.LENGTH_SHORT).show()
                        modelName = "flowers1"
                    }
                }

    }
}