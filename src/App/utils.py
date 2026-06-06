from PIL import Image
import numpy as np
import tensorflow as tf

def preprocess_image(pil_image):

    img = np.array(
        pil_image.convert("L"),
        dtype=np.float32
    )

    # Recover original WM811K encoding
    img = np.round(img / 127.5)

    # Apply the SAME transformation used in training
    img = np.maximum(img - 1.0, 0.0)

    img = tf.convert_to_tensor(img)

    img = tf.expand_dims(img, -1)

    img = tf.image.resize(
        img,
        (96,96),
        method="nearest"
    )

    return img.numpy()