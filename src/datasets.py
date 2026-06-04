import numpy as np
import pandas as pd
import tensorflow as tf
import os
import matplotlib.pyplot as plt
from tqdm.notebook import tqdm



class WM_811K():

    defect_to_int = {
        'none'      : -1,
        'Center'    :  0,
        'Loc'       :  1,
        'Edge-Ring' :  2,
        'Edge-Loc'  :  3,
        'Scratch'   :  4,
        'Random'    :  5,
        'Donut'     :  6,
        'Near-full' :  7,
    }

    defect_from_int = { v:k for k,v in defect_to_int.items() }

    n_classes = len(defect_to_int)


    @staticmethod
    def preprocess_image(img: 'tf.Tensor|np.array', size: tuple[int,int]):
        img = tf.convert_to_tensor(img, dtype=tf.float32)
        img = tf.squeeze(img)
        img = tf.expand_dims(img, -1)
        img = tf.maximum(img - 1.0, 0.0)
        img = tf.image.resize(img, size)
        return img

    
    @staticmethod
    def augment_image(img: tf.Tensor):
        img = tf.image.random_flip_left_right(img)
        img = tf.image.random_flip_up_down(img)
        img = tf.image.rot90(img, k=np.random.randint(4))
        img = tf.minimum(img * (1.0 + np.random.rand()), 1.0)
        return img


    def __init__(self, imsize=(64,64)):
        self.imsize = imsize
        self.class_samples = { i: [] for i in WM_811K.defect_from_int }

        print('reading wafermaps')
        path = os.path.join('..', 'data', 'LSWMD_slimmed.pkl')
        df = pd.read_pickle(path)
        for row in tqdm(df.itertuples(index=False), total=len(df)):
            i = WM_811K.defect_to_int[row.label]
            img = WM_811K.preprocess_image(row.waferMap, self.imsize)
            self.class_samples[i].append(img)


    def dataset_single_defect(self):
        def _generator():
            while True:
                label = np.random.randint(WM_811K.n_classes) - 1
                samples = self.class_samples[label]
                img = samples[np.random.randint(len(samples))]
                img = WM_811K.augment_image(img)
                yield (img, tf.one_hot(label, depth=WM_811K.n_classes-1))
        
        return tf.data.Dataset.from_generator(_generator,
            output_types=(tf.float32, tf.float32),
            output_shapes=((*self.imsize, 1), (WM_811K.n_classes - 1,)),
        ).repeat()


    def __create_multi_defect_sample(self):
        input_img = tf.zeros((*self.imsize, 1))
        channels = [tf.zeros(self.imsize) for _ in range(WM_811K.n_classes - 1)]
        label_vec = tf.zeros((WM_811K.n_classes - 1))
        
        class_probabilities = np.random.rand(WM_811K.n_classes - 1) * np.random.randint(10)     # class picking order * occasional none 
        while np.sum(class_probabilities) > 0.0:
            # get an image sample
            label = np.argmax(class_probabilities)
            samples = self.class_samples[label]
            img = samples[np.random.randint(len(samples))]
            img = WM_811K.augment_image(img)

            # roughly check how much information will be lost/gained
            total = tf.reduce_sum(input_img) + 0.1
            inf_loss = tf.reduce_sum(input_img - tf.maximum(input_img - img, 0.0))
            inf_gain = tf.reduce_sum(tf.maximum(img - input_img, 0.0))

            # ...and add img to total if acceptable
            if inf_loss < .25 * total and inf_gain > .25 * total:    
                input_img = tf.maximum(input_img, img)
                channels[label] = tf.squeeze(img)
                label_vec = tf.maximum(label_vec, tf.one_hot(label, depth=WM_811K.n_classes-1))

            class_probabilities[label] = 0.0

        img_stack = tf.stack(channels, axis=-1)
        return input_img, img_stack, label_vec


    def dataset_multi_defect_segmentation(self):
        def _generator():
            while True:
                x,y,_ = self.__create_multi_defect_sample()
                yield x,y

        return tf.data.Dataset.from_generator(_generator,
            output_types=(tf.float32, tf.float32),
            output_shapes=((*self.imsize,1), (*self.imsize, WM_811K.n_classes - 1)),
        ).repeat()


    def dataset_multi_defect_classification(self):
        def _generator():
            while True:
                _,x,y = self.__create_multi_defect_sample()
                yield x,y
            
        return tf.data.Dataset.from_generator(_generator,
            output_types=(tf.float32, tf.float32),
            output_shapes=((*self.imsize, WM_811K.n_classes - 1), (WM_811K.n_classes - 1,))
        ).repeat()


    def dataset_multi_defect_fullstack(self):
        def _generator():
            while True:
                x,_,y = self.__create_multi_defect_sample()
                yield x,y
            
        return tf.data.Dataset.from_generator(_generator,
            output_types=(tf.float32, tf.float32),
            output_shapes=((*self.imsize,1), (WM_811K.n_classes - 1,))
        ).repeat()
