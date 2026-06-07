import tensorflow as tf



class SpatialAttention(tf.keras.layers.Layer):
    def __init__(self, kernel_size=7, **kwargs):
        """
        kernel_size: 7x7 is the standard established by the CBAM paper. 
        It gives the convolution a wide enough receptive field to understand 
        the geometry around a pixel.
        """
        super(SpatialAttention, self).__init__(**kwargs)
        
        # The single convolution layer that creates the final mask
        self.conv = tf.keras.layers.Conv2D(
            filters=1, 
            kernel_size=kernel_size, 
            padding='same', 
            activation='sigmoid', 
            use_bias=False # Bias is unnecessary here
        )

    def call(self, inputs):
        # 1. Average Pooling across the channel axis (axis=-1)
        # Shape changes from (B, H, W, C) -> (B, H, W, 1)
        avg_pool = tf.reduce_mean(inputs, axis=-1, keepdims=True)
        
        # 2. Max Pooling across the channel axis
        # Shape changes from (B, H, W, C) -> (B, H, W, 1)
        max_pool = tf.reduce_max(inputs, axis=-1, keepdims=True)
        
        # 3. Concatenate the two maps together
        # Shape becomes (B, H, W, 2)
        concat = tf.concat([avg_pool, max_pool], axis=-1)
        
        # 4. Pass through convolution and sigmoid to generate the mask
        # Shape becomes (B, H, W, 1), with values between 0.0 and 1.0
        attention_mask = self.conv(concat)
        
        # 5. Multiply the mask against the original inputs
        return inputs * attention_mask

    # Required so you can save and load your model later without errors
    def get_config(self):
        config = super(SpatialAttention, self).get_config()
        return config
