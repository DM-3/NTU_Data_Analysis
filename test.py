import os
from tensorflow.keras.models import load_model
from PIL import Image
import numpy as np
import tensorflow as tf

# Load model
# model = load_model("src/best_wafer_cnn.keras")
model = load_model("models/direct_classifier_cnn.keras")

# TARGET_SIZE = (96, 96) # for best_wafer_cnn.keras
TARGET_SIZE = (64, 64) # for direct_classifier_cnn.keras

label_names = [
    "Center", "Donut", "Edge-Loc", "Edge-Ring",
    "Loc", "Random", "Scratch", "Near-full", "None"
]

def preprocess(pil_image):
    img = pil_image.convert("L")
    arr = np.array(img).astype(np.float32)

    # ✅ MATCH TRAINING
    arr = np.round(arr / 127.5)

    arr = np.expand_dims(arr, axis=-1)

    arr = tf.image.resize_with_pad(
    arr,
    TARGET_SIZE[0],
    TARGET_SIZE[1],
    method="nearest"
).numpy()

    arr = np.expand_dims(arr, axis=0)

    return arr

# Folder path
folder = "generated_images"

correct = 0
total = 0

for file in os.listdir(folder):
    if file.endswith(".png"):

        true_label = file.split("_")[1].split(".")[0]

        path = os.path.join(folder, file)
        img = Image.open(path)

        x = preprocess(img)
        preds = model.predict(x)[0]

        pred_label = label_names[np.argmax(preds)]

        if pred_label == true_label:
            correct += 1
        
        total += 1

        print(f"{file} → TRUE: {true_label}, PRED: {pred_label}")

print(f"\nAccuracy: {correct}/{total} = {correct/total:.2f}")