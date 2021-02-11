package com.lmoroney.odml.helpers;
/*
 * Copyright 2020 The TensorFlow Authors. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


import android.content.Context;
import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;
import android.util.Log;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import org.tensorflow.lite.support.label.Category;
import org.tensorflow.lite.task.text.nlclassifier.NLClassifier;

/** Load TfLite model and provide predictions with task api. */
public class TextClassificationClient {
    private static final String TAG = "TaskApi";
    private static final String MODEL_PATH = "model.tflite";
    private static final String LABELS_PATH = "labels.txt";
    private static final List<String> labels = new ArrayList<>();
    private final Context context;

    NLClassifier classifier;

    public TextClassificationClient(Context context) {
        this.context = context;
    }

    public void load() {
        try {
            classifier = NLClassifier.createFromFile(context, MODEL_PATH);
            read_labels(context.getAssets(), LABELS_PATH);
        } catch (IOException e) {
            Log.e(TAG, e.getMessage());
        }
    }


    public void unload() {
        classifier.close();
        classifier = null;
    }

    private static void read_labels(AssetManager assetManager, String labelsPath) throws IOException{
        InputStream ims = assetManager.open(labelsPath);
        BufferedReader reader = new BufferedReader(new InputStreamReader(ims));
        // Each line in the label file is a label.
        while (reader.ready()) {
            labels.add(reader.readLine());
        }

    }

    public List<Result> classify(String text) {
        List<Category> apiResults = classifier.classify(text);
        List<Result> results = new ArrayList<>(apiResults.size());
        for (int i = 0; i < apiResults.size(); i++) {
            Category category = apiResults.get(i);
            results.add(new Result("" + i, labels.get(i), category.getScore()));
        }
        Collections.sort(results);
        return results;
    }
}