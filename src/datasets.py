import numpy as np
import pandas as pd
import os
import matplotlib.pyplot as plt
import tensorflow as tf



class WM_811K():
    def __init__(self, imsize=(64,64)):
        path = os.path.join('..', 'data', 'LSWMD_slimmed.pkl')
        df = pd.read_pickle(path)

        image_list = [tf.image.resize(tf.expand_dims(tf.convert_to_tensor(x), -1), imsize) 
                                                     for x in df['waferMap']]
        self.X = tf.convert_to_tensor(image_list)

        df['label_int'], lnames = pd.factorize(df['label'])
        self.labels = df['label_int'].to_numpy()
        self.label_names = lnames

    def preview(self):
        _, axs = plt.subplots(3,3)
        axs = axs.flatten()
        for i, (ax,name) in enumerate(zip(axs, self.label_names)):
            idx = np.where(self.labels == i)[0][0]

            indices = np.where(self.labels == i)[0]
            idx = indices[np.random.randint(0, len(indices))]
            ax.imshow(self.X[idx])
            ax.set_title(name)

class WM_811K_preprocessed():

    def __init__(self):
        data = np.load('wafer_dataset_96x96.npz')

        self.X_train = data['X_train']
        self.X_test =  data['X_test']
        self.labels_train =data['y_train']
        self.labels_test = data['y_test']
        self.X = np.concatenate((data['X_train'], data['X_test']), axis=0)
        self.labels = np.concatenate((data['y_train'], data['y_test']), axis=0)
        
        self.label_names = [
            'Center', 'Donut', 'Edge-Loc', 'Edge-Ring', 
            'Loc', 'Near-full', 'Random', 'Scratch', 'none'
        ]

    def preview(self):
        _, axs = plt.subplots(3,3)
        axs = axs.flatten()
        for i, (ax,name) in enumerate(zip(axs, self.label_names)):
            idx = np.where(self.labels == i)[0][0]

            indices = np.where(self.labels == i)[0]
            idx = indices[np.random.randint(0, len(indices))]
            
            ax.imshow(self.X[idx].squeeze())
            ax.set_title(name)

