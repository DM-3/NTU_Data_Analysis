import tensorflow as tf

class SpatialAttention(tf.keras.layers.Layer):

    def __init__(self, kernel_size=7, **kwargs):
        super().__init__(**kwargs)

        self.conv = tf.keras.layers.Conv2D(
            filters=1,
            kernel_size=kernel_size,
            padding='same',
            activation='sigmoid',
            use_bias=False
        )

    def call(self, inputs):

        avg_pool = tf.reduce_mean(
            inputs,
            axis=-1,
            keepdims=True
        )

        max_pool = tf.reduce_max(
            inputs,
            axis=-1,
            keepdims=True
        )

        concat = tf.concat(
            [avg_pool, max_pool],
            axis=-1
        )

        attention_mask = self.conv(concat)

        return inputs * attention_mask

    def get_config(self):
        config = super().get_config()
        return config