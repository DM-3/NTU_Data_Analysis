# ==================================================
# MODEL LOGIC
# ==================================================
import numpy as np
import os
import streamlit as st
from tensorflow.keras.models import load_model
from config import LABELS, MODEL_DIR
import tensorflow as tf
from custom import SpatialAttention
tf.config.run_functions_eagerly(True)

print("MODEL DIR:", MODEL_DIR)
print("FILES:", os.listdir(MODEL_DIR))

@st.cache_resource
def load_segmentation_model():
    return load_model(
        os.path.join(MODEL_DIR, "multi_defect_segmentation.keras"),
        compile=False
    )

@st.cache_resource
def load_fullstack_model():
    return load_model(
        os.path.join(MODEL_DIR, "multi_defect_fullstack.keras"),
        compile=False,
        custom_objects={
            "SpatialAttention": SpatialAttention
        }
    )

seg_model = load_segmentation_model()
fullstack_model = load_fullstack_model()

print("Segmentation model loaded")
print("Fullstack model loaded")

def predict_segmentation(img_batch):

    masks = seg_model(
        img_batch,
        training=False
    )[0].numpy()

    print("MASK SHAPE:", masks.shape)
    print("MASK MIN:", masks.min())
    print("MASK MAX:", masks.max())
    print("MASK MEAN:", masks.mean())

    scores = np.max(
        masks,
        axis=(0,1)
    )

    print("SCORES:", scores)

    return masks, scores

def predict_classes(img_batch):

    probs = fullstack_model(
        img_batch,
        training=False
    )[0].numpy()

    return probs

# ← REMOVED @st.cache_data here.
# Using @st.cache_data inside a function that calls @st.cache_resource objects
# causes a cache-lock deadlock in Streamlit — the function hangs indefinitely.
# The models themselves are already cached by @st.cache_resource, so this
# wrapper cache is unnecessary and harmful.

def predict_defects(image, preprocess_fn):

    img = preprocess_fn(image)

    img_batch = np.expand_dims(img, axis=0)

    masks, mask_scores = predict_segmentation(img_batch)

    probs = predict_classes(img_batch)

    img = preprocess_fn(image)

    print("PREPROCESSED SHAPE:", img.shape)
    print("PREPROCESSED MIN:", img.min())
    print("PREPROCESSED MAX:", img.max())
    print("UNIQUE VALUES:", np.unique(img)[:20])

    img_batch = np.expand_dims(img, axis=0)

    print("BATCH SHAPE:", img_batch.shape)
    return {
        "masks": masks,
        "mask_scores": mask_scores,
        "probabilities": probs
    }