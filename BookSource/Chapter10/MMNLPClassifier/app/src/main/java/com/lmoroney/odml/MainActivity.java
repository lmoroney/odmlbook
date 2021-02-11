package com.lmoroney.odml;

import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;
import android.os.Handler;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import com.lmoroney.odml.helpers.TextClassificationClient;
import com.lmoroney.odml.helpers.Result;

import java.util.List;

public class MainActivity extends AppCompatActivity {
    private EditText txtInput;
    private TextView txtOutput;
    private Button btnClassify;
    private TextClassificationClient client;
    private Handler handler;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        client = new TextClassificationClient(getApplicationContext());
        client.load();
        txtInput = findViewById(R.id.txtInput);
        txtOutput = findViewById(R.id.txtOutput);
        btnClassify = findViewById(R.id.btnClassify);
        btnClassify.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                String toClassify = txtInput.getText().toString();
                List<Result> results = client.classify(toClassify);
                showResult(toClassify, results);
            }
        });
    }

    /** Show classification result on the screen. */
    private void showResult(final String inputText, final List<Result> results) {
        // Run on UI thread as we'll updating our app UI
        runOnUiThread(
                () -> {
                    String textToShow = "Input: " + inputText + "\nOutput:\n";
                    for (int i = 0; i < results.size(); i++) {
                        Result result = results.get(i);
                        textToShow += String.format("    %s: %s\n", result.getTitle(), result.getConfidence());
                    }
                    textToShow += "---------\n";

                    txtOutput.setText(textToShow);
                });
    }
}