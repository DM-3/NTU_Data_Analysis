# ==================================================
# MODEL LOGIC
# ==================================================
import numpy as np
import os
import streamlit as st
import PIL
from tensorflow.keras.models import load_model
from config import MODEL_DIR
import tensorflow as tf
from datasets import WM_811K
from spatial_attention import SpatialAttention
tf.config.run_functions_eagerly(True)

import matplotlib.pyplot as plt


@st.cache_resource
def load_fullstack_model():
    return load_model(
        os.path.join(MODEL_DIR, "multi_defect_fullstack_fine_tuned.keras"),
        compile=False,
        custom_objects={
            "SpatialAttention": SpatialAttention
        }
    )

print("MODEL DIR:", MODEL_DIR)
print("FILES:", os.listdir(MODEL_DIR))

fullstack_model = load_fullstack_model()
segmentation_model = fullstack_model.layers[0]
classification_model = fullstack_model.layers[1]

print("Models loaded")

def predict_defects(image):
    if isinstance(image, PIL.Image.Image):
        image = np.array(image.convert("L"), dtype=np.float32)
    
    if np.max(image) > 2:       
        image /= 127.5

    image = WM_811K.preprocess_image(image, segmentation_model.input_shape[1:3])

    plt.imshow(image)
    plt.savefig('t.png')

    image = tf.expand_dims(image, axis=0)
    
    masks = segmentation_model(image)

    probs = classification_model(masks)
    print('defect probabilities:', ''.join(f'{p:.2f} ' for p in probs[0,:]))

    return {
        "masks": masks[0,:,:,:].numpy(),        
        "probabilities": probs[0,:].numpy()
    }
