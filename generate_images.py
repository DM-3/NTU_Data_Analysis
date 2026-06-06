import pickle
import numpy as np
import os
from PIL import Image

# =========================
# LOAD PKL
# =========================
with open("data/LSWMD_slimmed.pkl", "rb") as f:
    df = pickle.load(f)

print(type(df))
print(df.head())

# =========================
# SETTINGS
# =========================
label_names = [
    "Center", "Donut", "Edge-Loc", "Edge-Ring",
    "Loc", "Random", "Scratch", "Near-full"
]

os.makedirs("generated_images", exist_ok=True)

SAMPLES_PER_CLASS = 20
counter = 0

# =========================
# GENERATE IMAGES
# =========================
for label in label_names:

    # filter rows of that class
    subset = df[df["label"] == label]

    # safety check
    if len(subset) < SAMPLES_PER_CLASS:
        print(f"⚠️ Not enough samples for {label}")
        continue

    sampled = subset.sample(SAMPLES_PER_CLASS, random_state=42)

    for _, row in sampled.iterrows():
        wafer = np.array(row["waferMap"])  # shape ~ (H, W), values {0,1,2}

        # ✅ scale for visibility (CRITICAL)
        wafer_vis = (wafer / 2.0 * 255).astype(np.uint8)

        image = Image.fromarray(wafer_vis, mode="L")

        filename = f"generated_images/{counter}_{label}.png"
        image.save(filename)

        counter += 1

print("✅ Images generated from PKL correctly")