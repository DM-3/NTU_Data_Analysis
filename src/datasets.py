import numpy as np
import pandas as pd
import os
import matplotlib.pyplot as plt



class WM_811K():
    def __init__(self):
        path = os.path.join('..', 'data', 'LSWMD_slimmed.pkl')
        df = pd.read_pickle(path)
        self.X = df['waferMap'].apply(np.array).to_numpy()
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
