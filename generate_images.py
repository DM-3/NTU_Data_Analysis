import numpy as np
import os
from PIL import Image
import matplotlib.pyplot as plt
data = np.load("src/wafer_dataset_96x96.npz")
X = data["X_test"]
y = data["y_test"]

label_names = [
    "Center", "Donut", "Edge-Loc", "Edge-Ring",
    "Loc", "Random", "Scratch", "Near-full", "None"
]

os.makedirs("generated_images", exist_ok=True)

SAMPLES_PER_CLASS = 20
counter = 0

for class_id in range(len(label_names)):
    indices = np.where(y == class_id)[0]
    
    selected = np.random.choice(indices, SAMPLES_PER_CLASS, replace=False)

    for idx in selected:
        img = X[idx].squeeze()   # values: 0,1,2
        label = label_names[class_id]
        norm_img = img / 2.0   # since values are 0,1,2
        # Apply viridis colormap
        colored = plt.cm.viridis(norm_img)
        # Convert to 0-255 RGB
        rgb = (colored[:, :, :3] * 255).astype(np.uint8)
        # ✅ Ensure correct color mode
        image = Image.fromarray(rgb, mode="RGB")

        filename = f"generated_images/{counter}_{label}.png"
        image.save(filename)

        counter += 1

print("✅ Balanced colored dataset generated")